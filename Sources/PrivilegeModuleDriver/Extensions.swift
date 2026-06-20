import PrivilegeModule

extension AnyResource: @retroactive ResponseEncodable {}
extension AnyResource: @retroactive AsyncResponseEncodable {}
extension AnyResource: @retroactive RequestDecodable {}
extension AnyResource: @retroactive AsyncRequestDecodable {}
extension AnyResource: @retroactive Content {}

extension PM.QResource: @retroactive ResponseEncodable {}
extension PM.QResource: @retroactive AsyncResponseEncodable {}
extension PM.QResource: @retroactive RequestDecodable {}
extension PM.QResource: @retroactive AsyncRequestDecodable {}
extension PM.QResource: @retroactive Content {}

extension PM.PPrivilege: @retroactive ResponseEncodable {}
extension PM.PPrivilege: @retroactive AsyncResponseEncodable {}
extension PM.PPrivilege: @retroactive RequestDecodable {}
extension PM.PPrivilege: @retroactive AsyncRequestDecodable {}
extension PM.PPrivilege: @retroactive Content {}

extension PM.QPrivilege: @retroactive ResponseEncodable {}
extension PM.QPrivilege: @retroactive AsyncResponseEncodable {}
extension PM.QPrivilege: @retroactive RequestDecodable {}
extension PM.QPrivilege: @retroactive AsyncRequestDecodable {}
extension PM.QPrivilege: @retroactive Content {}
