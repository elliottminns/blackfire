import Foundation

extension String {

    func trimWhitespace() -> String {
        var characters = self.characters
        
        while characters.first == " " {
            characters.removeFirst()
        }

        while characters.last == " " {
            characters.removeLast()
        }

        return String(characters)
    }

    func split(withCharacter character: Character) -> [String] {
        return self.characters.split { $0 == character }.map { String($0) }
    }
}
