import Foundation

open class CommitStatistic: Serializable {
    open var commitId: String?
    open var processingTimeMs: Int?
    open var averageTimePerCommand: Int?
    open var errorReason: String?
    
    public init(commitId: String?, total: Int?, average: Int?, errorDesc: String?) {
        self.commitId = commitId
        self.processingTimeMs = total
        self.averageTimePerCommand = average
        self.errorReason = errorDesc
    }
}
