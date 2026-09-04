import Vapor
import PrivilegeModuleExtended

public struct AuthenticateData: Content, Sendable, CustomStringConvertible, Loggerable {
    public let token: EncryptedToken
    public let roleId: UUID
    
    enum CodingKeys: String, CodingKey {
        case token
        case roleId = "role_id"
    }
    
    public var json: [String: AnyCodable] {[
        "token": AnyCodable(self.token),
        "role_id": AnyCodable(self.roleId)
    ]}
    
    public var description: String {
        formatJson(json)
    }
    
    public init(token: EncryptedToken, roleId: UUID) {
        self.token = token
        self.roleId = roleId
    }
    
    public init(credential: String, tokenBase64: String, roleId: UUID) {
        self.token = .init(credential: credential, tokenBase64: tokenBase64)
        self.roleId = roleId
    }
}
