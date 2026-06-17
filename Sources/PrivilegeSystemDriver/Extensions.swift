import Vapor
import Policy
import PrivilegeModule
import PrivilegeSystem

extension PDomain: @retroactive ResponseEncodable {}
extension PDomain: @retroactive AsyncResponseEncodable {}
extension PDomain: @retroactive RequestDecodable {}
extension PDomain: @retroactive AsyncRequestDecodable {}
extension PDomain: @retroactive Content {}

extension QDomain: @retroactive ResponseEncodable {}
extension QDomain: @retroactive AsyncResponseEncodable {}
extension QDomain: @retroactive RequestDecodable {}
extension QDomain: @retroactive AsyncRequestDecodable {}
extension QDomain: @retroactive Content {}

extension PExtendedInfo: @retroactive ResponseEncodable {}
extension PExtendedInfo: @retroactive AsyncResponseEncodable {}
extension PExtendedInfo: @retroactive RequestDecodable {}
extension PExtendedInfo: @retroactive AsyncRequestDecodable {}
extension PExtendedInfo: @retroactive Content {}

extension QExtendedInfo: @retroactive ResponseEncodable {}
extension QExtendedInfo: @retroactive AsyncResponseEncodable {}
extension QExtendedInfo: @retroactive RequestDecodable {}
extension QExtendedInfo: @retroactive AsyncRequestDecodable {}
extension QExtendedInfo: @retroactive Content {}

extension PGroup: @retroactive ResponseEncodable {}
extension PGroup: @retroactive AsyncResponseEncodable {}
extension PGroup: @retroactive RequestDecodable {}
extension PGroup: @retroactive AsyncRequestDecodable {}
extension PGroup: @retroactive Content {}

extension QGroup: @retroactive ResponseEncodable {}
extension QGroup: @retroactive AsyncResponseEncodable {}
extension QGroup: @retroactive RequestDecodable {}
extension QGroup: @retroactive AsyncRequestDecodable {}
extension QGroup: @retroactive Content {}

extension PInfoSlice: @retroactive ResponseEncodable {}
extension PInfoSlice: @retroactive AsyncResponseEncodable {}
extension PInfoSlice: @retroactive RequestDecodable {}
extension PInfoSlice: @retroactive AsyncRequestDecodable {}
extension PInfoSlice: @retroactive Content {}

extension QInfoSlice: @retroactive ResponseEncodable {}
extension QInfoSlice: @retroactive AsyncResponseEncodable {}
extension QInfoSlice: @retroactive RequestDecodable {}
extension QInfoSlice: @retroactive AsyncRequestDecodable {}
extension QInfoSlice: @retroactive Content {}

extension PPolicy: @retroactive ResponseEncodable {}
extension PPolicy: @retroactive AsyncResponseEncodable {}
extension PPolicy: @retroactive RequestDecodable {}
extension PPolicy: @retroactive AsyncRequestDecodable {}
extension PPolicy: @retroactive Content {}

extension QPolicy: @retroactive ResponseEncodable {}
extension QPolicy: @retroactive AsyncResponseEncodable {}
extension QPolicy: @retroactive RequestDecodable {}
extension QPolicy: @retroactive AsyncRequestDecodable {}
extension QPolicy: @retroactive Content {}

extension PRole: @retroactive ResponseEncodable {}
extension PRole: @retroactive AsyncResponseEncodable {}
extension PRole: @retroactive RequestDecodable {}
extension PRole: @retroactive AsyncRequestDecodable {}
extension PRole: @retroactive Content {}

extension QRole: @retroactive ResponseEncodable {}
extension QRole: @retroactive AsyncResponseEncodable {}
extension QRole: @retroactive RequestDecodable {}
extension QRole: @retroactive AsyncRequestDecodable {}
extension QRole: @retroactive Content {}

extension Token: @retroactive ResponseEncodable {}
extension Token: @retroactive AsyncResponseEncodable {}
extension Token: @retroactive RequestDecodable {}
extension Token: @retroactive AsyncRequestDecodable {}
extension Token: @retroactive Content {}

extension PToken: @retroactive ResponseEncodable {}
extension PToken: @retroactive AsyncResponseEncodable {}
extension PToken: @retroactive RequestDecodable {}
extension PToken: @retroactive AsyncRequestDecodable {}
extension PToken: @retroactive Content {}

extension QToken: @retroactive ResponseEncodable {}
extension QToken: @retroactive AsyncResponseEncodable {}
extension QToken: @retroactive RequestDecodable {}
extension QToken: @retroactive AsyncRequestDecodable {}
extension QToken: @retroactive Content {}

extension PUser: @retroactive ResponseEncodable {}
extension PUser: @retroactive AsyncResponseEncodable {}
extension PUser: @retroactive RequestDecodable {}
extension PUser: @retroactive AsyncRequestDecodable {}
extension PUser: @retroactive Content {}

extension QUser: @retroactive ResponseEncodable {}
extension QUser: @retroactive AsyncResponseEncodable {}
extension QUser: @retroactive RequestDecodable {}
extension QUser: @retroactive AsyncRequestDecodable {}
extension QUser: @retroactive Content {}

extension PUserInfo: @retroactive ResponseEncodable {}
extension PUserInfo: @retroactive AsyncResponseEncodable {}
extension PUserInfo: @retroactive RequestDecodable {}
extension PUserInfo: @retroactive AsyncRequestDecodable {}
extension PUserInfo: @retroactive Content {}

extension QUserInfo: @retroactive ResponseEncodable {}
extension QUserInfo: @retroactive AsyncResponseEncodable {}
extension QUserInfo: @retroactive RequestDecodable {}
extension QUserInfo: @retroactive AsyncRequestDecodable {}
extension QUserInfo: @retroactive Content {}

extension PUserInGroup: @retroactive ResponseEncodable {}
extension PUserInGroup: @retroactive AsyncResponseEncodable {}
extension PUserInGroup: @retroactive RequestDecodable {}
extension PUserInGroup: @retroactive AsyncRequestDecodable {}
extension PUserInGroup: @retroactive Content {}

extension QUserInGroup: @retroactive ResponseEncodable {}
extension QUserInGroup: @retroactive AsyncResponseEncodable {}
extension QUserInGroup: @retroactive RequestDecodable {}
extension QUserInGroup: @retroactive AsyncRequestDecodable {}
extension QUserInGroup: @retroactive Content {}

extension DomainTGroup: @retroactive ResponseEncodable {}
extension DomainTGroup: @retroactive AsyncResponseEncodable {}
extension DomainTGroup: @retroactive RequestDecodable {}
extension DomainTGroup: @retroactive AsyncRequestDecodable {}
extension DomainTGroup: @retroactive Content {}

extension RoleTGroup: @retroactive ResponseEncodable {}
extension RoleTGroup: @retroactive AsyncResponseEncodable {}
extension RoleTGroup: @retroactive RequestDecodable {}
extension RoleTGroup: @retroactive AsyncRequestDecodable {}
extension RoleTGroup: @retroactive Content {}

extension RoleTUserInGroup: @retroactive ResponseEncodable {}
extension RoleTUserInGroup: @retroactive AsyncResponseEncodable {}
extension RoleTUserInGroup: @retroactive RequestDecodable {}
extension RoleTUserInGroup: @retroactive AsyncRequestDecodable {}
extension RoleTUserInGroup: @retroactive Content {}

extension UserTDomain: @retroactive ResponseEncodable {}
extension UserTDomain: @retroactive AsyncResponseEncodable {}
extension UserTDomain: @retroactive RequestDecodable {}
extension UserTDomain: @retroactive AsyncRequestDecodable {}
extension UserTDomain: @retroactive Content {}

extension UserTGroup: @retroactive ResponseEncodable {}
extension UserTGroup: @retroactive AsyncResponseEncodable {}
extension UserTGroup: @retroactive RequestDecodable {}
extension UserTGroup: @retroactive AsyncRequestDecodable {}
extension UserTGroup: @retroactive Content {}

extension UserTRole: @retroactive ResponseEncodable {}
extension UserTRole: @retroactive AsyncResponseEncodable {}
extension UserTRole: @retroactive RequestDecodable {}
extension UserTRole: @retroactive AsyncRequestDecodable {}
extension UserTRole: @retroactive Content {}
