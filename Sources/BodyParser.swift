class BodyParser: Middleware {
    
    func handle(request: Request, response: Response, next: () -> ()) {

        defer { next() }

        guard let contentTypeHeader = request.headers["content-type"] else {
            return
        }

        let contentTypeTokens = contentTypeHeader.split(withCharacter: ";").map { $0.trimWhitespace() }
        guard let contentType = contentTypeTokens.first where 
            contentType == "application/json" else { return }
        
        let parser = JSONParser(data: request.body)
        let json = parser.parse()
        
        for (key, value) in json {
            request.data[key] = value
        }
    }
}
