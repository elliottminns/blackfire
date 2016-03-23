class JSONParser: Middleware {
    
    func handle(request: Request, response: Response, next: () -> ()) {

        defer { next() }

        guard let contentTypeHeader = request.headers["content-type"] else {
            return
        }

        let contentTypeTokens = contentTypeHeader.splitWithCharacter(";").map { $0.trimWhitespace() }
        guard let contentType = contentTypeTokens.first where 
            contentType == "application/json" else { return }
        
        do {

            let jsonString = try request.body.toString()
            let json = parseJsonString(jsonString)
		
		    for (key, value) in json {
                request.data[key] = value
            }
        } catch {
        
        }
    }

    
    func boolValue(string string: String) -> Bool {
        return string == "true"
    }
    
    func isBoolValue(string string: String) -> Bool {
        return string == "true" || string == "false"
    }
    
    func isDoubleValue(string string: String) -> Bool {
        return string.contains(".")
    }
    
    func isStringValue(string string: String) -> Bool {
        return (string.hasPrefix("'") && string.hasSuffix("'")) || (string.hasPrefix("\"") && string.hasSuffix("\""))
    }
    
    func cleanString(string: String) -> String {
        if (string.hasPrefix("'") && string.hasSuffix("'")) || (string.hasPrefix("\"") && string.hasSuffix("\"")) {
            var value = string
            value.remove(at: value.startIndex)
            value.remove(at: value.endIndex.predecessor())
            return value
        } else {
            return string
        }
    }
    
    func splitIntoKeyValues(string: String) -> [(key: String?, value: String?)] {
        
        var pairs = [(key: String?, value: String?)]()
        
        var string = string
        if string.hasPrefix("{") {
            string.remove(at: string.startIndex)
        }
        
        if string.hasSuffix("}") {
            string.remove(at: string.endIndex.predecessor())
        }
        
        let characters = string.characters
        
        var key: String? = nil
        
        var inString = false
        var inObject = false
        var objectLevel = 0
        var arrayLevel = 0
        
        var buffer = ""
        
        var escapeCharacter = false
        
        for c in characters {
            
            if c == "{" {
                
                inObject = true
                
                objectLevel += 1
            }
            
            if c == "}" {
                
                objectLevel -= 1
                
                inObject = objectLevel != 0
            }
            
            if c == "[" {
                arrayLevel += 1
            }
            
            if c == "]" {
                arrayLevel -= 1
            }
            
            
            if c == "\"" || c == "'" && !escapeCharacter {
                inString = !inString
            }
            
            if c == ":" && !inString && key == nil && !inObject && arrayLevel == 0 {
                if key == nil {
                    key = cleanString(buffer.trimWhitespace())
                }
                buffer = ""
            } else if c == "," && !inString && !inObject && arrayLevel == 0 {
                pairs.append((key: key, value: buffer.trimWhitespace()))
                buffer = ""
                key = nil
            } else {
                buffer.append(c)
            }
            
            if escapeCharacter {
                escapeCharacter = false
            }
            
            if c == "\\" {
                escapeCharacter = true
            }
        }
        
        if let key = key {
            pairs.append((key: key, value: buffer.trimWhitespace()))
        }
        
        
        
        return pairs
        
    }
    
    func parseJsonString(string: String) -> [String: Any] {
        var json = [String: Any]()
        
        let pairs = splitIntoKeyValues(string)
        
        for pair in pairs {
            if let key = pair.key, value = pair.value {
                if let value = valueForProperty(value) {
                    json[key] = value
                } else if let value = arrayForString(value) {
                    json[key] = value
                } else {
                    json[key] = parseJsonString(value)
                }
            }
        }
        
        return json
    }
    
    func arrayForString(string: String) -> [Any]? {
        
        var string = string
        
        if !string.hasPrefix("[") {
            return nil
        } else {
            string.remove(at: string.startIndex)
        }
        
        if string.hasSuffix("]") {
            string.remove(at: string.endIndex.predecessor())
        }
        
        var array = [Any]()
        let components = string.componentsSeparated(by: ",")
        
        for component in components {
            let component = component.trimWhitespace()
            let value: Any?
            if component.hasPrefix("{") {
                value = parseJsonString(component)
            } else {
                value = valueForProperty(component)
            }
            
            if let value = value {
                array.append(value)
            }
        }
        return array
    }
    
    func valueForProperty(string: String) -> Any? {
        if string.hasPrefix("{") {
            return nil
        }
        
        if string.hasPrefix("[") {
            return nil
        }
        
        if isStringValue(string: string) {
            let value = cleanString(string)
            return value
        } else if isBoolValue(string: string) {
            return boolValue(string: string)
        } else if isDoubleValue(string: string) {
            return Double(string)
        } else if let value = Int(string) {
            return value
        }
        
        return nil
    }


}
