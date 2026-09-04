import Vapor
import LoggingAdvanced
import Cryptos

/// 记录用户的认证信息，用于之后的认证验证机制
@frozen
public struct WhitelistAuthData: Content, Hashable, CustomStringConvertible, Loggerable {
    public let token: QToken
    public let roles: [QRole]
    
    public var json: [String: AnyCodable] {[
        "token": AnyCodable(self.token),
        "roles": AnyCodable(self.roles)
    ]}
    
    public var description: String {
        formatJson(json)
    }
    
    public init(token: QToken, roles: [QRole]) {
        self.token = token
        self.roles = roles
    }
}
