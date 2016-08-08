//
//  OpenSSLHelper.m
//  SwiftLibWithC
//
//  Created by Igor Kravchenko on 5/6/16.
//  Copyright © 2016 Igor Kravchenko. All rights reserved.
//

#import "OpenSSLHelper.h"
#import "SECP256R1KeyPairContainer+Private.h"

#include <stdbool.h>
#include <string.h>
#include <assert.h>
#include <openssl/evp.h>

#include <string.h>
#include <openssl/sha.h>

/*
 *  Use this function to encrypt data with AES 256 GCM
 *
 *  @param  key         256 AES key.
 *  @param  iv          Initialization vector
 *  @param  aad         Additional authn data
 *  @param  plain_text  Plain text message to be encrypted
 *
 *  @returns Returns AESGCM_EncryptionResult struct, which contains cipher text and authentication tag
 *           YOU SHOULD TO DEALLOCATE AESGCM_EncryptionResult WITH aes_gcm_free_encryption_result()
 */
static void aes_gcm_encrypt(unsigned char * key,        int key_size,
                            unsigned char * iv,         int iv_size,
                            unsigned char * aad,        int aad_size,
                            unsigned char * plain_text, int plain_text_size,
                            AESGCM_EncryptionResult * result)
{
    const int tag_size = 16;
    
    int outlen;
    unsigned char * cipherBuf = malloc(sizeof(unsigned char) * (plain_text_size + 16));
    unsigned char tagBuf[tag_size];
    
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    
    EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_size, NULL);
    EVP_EncryptInit_ex(ctx, NULL, NULL, key, iv);
    
    if (aad != NULL)
    {
        EVP_EncryptUpdate(ctx, NULL, &outlen, aad, aad_size);
    }
    
    EVP_EncryptUpdate(ctx, cipherBuf, &outlen, plain_text, plain_text_size);
    
    result->cipher_text = malloc(sizeof(unsigned char) * outlen);
    memcpy(result->cipher_text, cipherBuf, outlen);
    result->cipher_text_size = outlen;
    
    EVP_EncryptFinal_ex(ctx, cipherBuf, &outlen);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, tag_size, tagBuf);
    
    result->auth_tag = malloc(sizeof(unsigned char) * tag_size);
    memcpy(result->auth_tag, tagBuf, tag_size);
    result->auth_tag_size = tag_size;
    
    EVP_CIPHER_CTX_free(ctx);
    free(cipherBuf);
}

static void aes_gcm_free_encryption_result(AESGCM_EncryptionResult * encryption_result)
{
    if (encryption_result == NULL)
    {
        return;
    }
    
    if (encryption_result->auth_tag != NULL)
    {
        free(encryption_result->auth_tag);
    }
    
    if (encryption_result->cipher_text != NULL)
    {
        free(encryption_result->cipher_text);
    }
    
    free(encryption_result);
}

/*
 *  Use this function to decrypt data with AES 256 GCM
 *
 *  @param  key         256 AES key.
 *  @param  iv          Initialization vector
 *  @param  aad         Additional authn data
 *  @param  cipher_text Cipher text to be decrypted
 *  @param  auth_tag    Authentication tag
 *
 *  @returns Returns AesGcmDecryptionResult struct, which contains decrypted plain text
 *           YOU SHOULD TO DEALLOCATE DecryptionResult WITH aes_gcm_free_decryption_result()
 */
static bool aes_gcm_decrypt(unsigned char * key,         int key_size,
                            unsigned char * iv,          int iv_size,
                            unsigned char * aad,         int aad_size,
                            unsigned char * cipher_text, int cipher_text_size,
                            unsigned char * auth_tag,    int auth_tag_size,
                            AESGCM_DecryptionResult * result)
{
    EVP_CIPHER_CTX * ctx = EVP_CIPHER_CTX_new();
    int outlen, rv;
    unsigned char * outbuf = malloc(sizeof(unsigned char) * cipher_text_size);
    
    EVP_DecryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL);
    EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, iv_size, NULL);
    EVP_DecryptInit_ex(ctx, NULL, NULL, key, iv);
    if (aad != NULL && !EVP_DecryptUpdate(ctx, NULL, &outlen, aad, aad_size))
    {
        EVP_CIPHER_CTX_free(ctx);
        free(outbuf);
        assert(0); // Problems with updating aad
        return false;
    }
    
    /* Decrypt plaintext */
    if (!EVP_DecryptUpdate(ctx, outbuf, &outlen, cipher_text, cipher_text_size))
    {
        EVP_CIPHER_CTX_free(ctx);
        free(outbuf);
        assert(0); // Problems with cipher text decrypt
        return false;
    }
    
    /* Setting plain text */
    result->plain_text = malloc(sizeof(unsigned char) * outlen);
    memcpy(result->plain_text, outbuf, outlen);
    result->plain_text_size = outlen;
    
    /* Set expected tag value. */
    if (!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, auth_tag_size, auth_tag))
    {
        EVP_CIPHER_CTX_free(ctx);
        free(outbuf);
        assert(0); // Problems in setting tag
        return false;
    }
    
    /* Finalise: note get no output for GCM */
    rv = EVP_DecryptFinal_ex(ctx, outbuf+outlen, &outlen);
    /*
     * Print out return value. If this is not successful authentication
     * failed and plaintext is not trustworthy.
     */
    
    EVP_CIPHER_CTX_free(ctx);
    
    free(outbuf);
    
    // unsuccessful authentication
    if (rv <= 0)
    {
        if (result->plain_text)
        {
            free(result->plain_text);
        }
        
        free(result);
        result = NULL;
        return false;
    }
    
    return true;
}

static void aes_gcm_free_decryption_result(AESGCM_DecryptionResult * decryption_result)
{
    if (decryption_result == NULL)
    {
        return;
    }
    
    if (decryption_result->plain_text != NULL)
    {
        free(decryption_result->plain_text);
    }
    
    free(decryption_result);
}

static bool simpleSHA1(const void* input, unsigned long length, char* output)
{
    unsigned char md[SHA_DIGEST_LENGTH];
    
    SHA_CTX context;
    if (!SHA1_Init(&context))
        return false;
    
    if (!SHA1_Update(&context, (unsigned char*)input, length))
        return false;
    
    if (!SHA1_Final(md, &context))
        return false;
    
    for (int i = 0; i < SHA_DIGEST_LENGTH; i++)
        sprintf(&output[i*2], "%02x", (unsigned int)md[i]);
    
    return true;
}

@implementation OpenSSLHelper

+ (instancetype)sharedInstance
{
    static OpenSSLHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)AES_GSM_encrypt:(unsigned char *)key
                keySize:(int)keySize
                     iv:(unsigned char *)iv
                 ivSize:(int)ivSize
                    aad:(unsigned char *)aad
                aadSize:(int)aadSize
              plainText:(unsigned char *)plainText
          plainTextSize:(int)plainTextSize
                 result:(AESGCM_EncryptionResult *)result
{
    aes_gcm_encrypt(key, keySize, iv, ivSize, aad, aadSize, plainText, plainTextSize, result);
}

- (void)AES_GSM_freeEncryptionResult:(AESGCM_EncryptionResult *)encryptionResult
{
    aes_gcm_free_encryption_result(encryptionResult);
}

- (BOOL)AES_GSM_decrypt:(unsigned char *)key
                keySize:(int)keySize
                     iv:(unsigned char *)iv
                 ivSize:(int)ivSize
                    aad:(unsigned char *)aad
                aadSize:(int)aadSize
             cipherText:(unsigned char *)cipherText
         cipherTextSize:(int)cipherTextSize
                authTag:(unsigned char *)authTag
            authTagSize:(int)authTagSize
                 result:(AESGCM_DecryptionResult *)result
{
    return aes_gcm_decrypt(key, keySize, iv, ivSize, aad, aadSize, cipherText, cipherTextSize, authTag, authTagSize, result);
}

- (void)AES_GSM_freeDecryptionResult:(AESGCM_DecryptionResult *)decryptionResult
{
    aes_gcm_free_decryption_result(decryptionResult);
}

- (BOOL)simpleSHA1:(const void *)input length:(unsigned long)length output:(char *)output
{
    return simpleSHA1(input, length, output);
}

- (NSInteger)shaDigestLength
{
    return SHA_DIGEST_LENGTH;
}

@end
