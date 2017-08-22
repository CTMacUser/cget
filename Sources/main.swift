import Foundation
import Commander
import HeliumLogger
import LoggerAPI


/// Potential command-line return values.
enum ReturnCode: Int32 {
    case badUrlString = 10, retrievalError, noResponse
}

HeliumLogger.use()
let main = command(
    Flag("suppress-header", description: "Do not write a MIME content header before the data", default: false),
    Argument<String>("URL", description: "Location of the resource to be downloaded")
) { (suppressHeader: Bool, urlArgument: String) in
    // Sanity-check the command-line arguments.
    guard let url = URL(string: urlArgument) else {
        Log.error("Argument \"\(urlArgument)\" cannot be converted to a URL.")
        exit(ReturnCode.badUrlString.rawValue)
    }

    // Make sure the program doesn't end before the download finishes.
    let semaphore = DispatchSemaphore(value: 0)

    // Download the URL.
    let session = URLSession(configuration: .ephemeral)
    let task = session.dataTask(with: url) {
        // Unblock execution.
        defer { semaphore.signal() }

        // Sanity-check the download results.
        if let error = $2 {
            Log.error("Retrieval Error: \(error)")
            exit(ReturnCode.retrievalError.rawValue)
        }
        guard let response = $1 else {
            Log.error("Retrieval Error: no response")
            exit(ReturnCode.noResponse.rawValue)
        }
        guard let data = $0 else {
            Log.info("(no data)")
            return
        }

        // Check if the data can be converted to text.
        let haveText: Bool
        if let mainType = response.mimeType?.components(separatedBy: "/").first {
            haveText = mainType == "text"
        } else {
            haveText = false
        }

        let encoding: String.Encoding?
        if let encodingName = response.textEncodingName {
            let encodingCF = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            encoding = encodingCF == kCFStringEncodingInvalidId ? nil : String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(encodingCF))
        } else {
            encoding = nil
        }

        // If the result is preparable text,...
        if !suppressHeader {
            print("Content-Type: \(response.mimeType ?? "application/octet-stream")")
        }
        if haveText, let textEncoding = encoding, let dataString = String(data: data, encoding: textEncoding) {
            // ...print it out as such,...
            if !suppressHeader {
                print()
            }
            print(dataString)
        } else {
            // ...otherwise print it as Base-64 binary.
            if !suppressHeader {
                print("Content-Transfer-Encoding: base64")
                print()
            }
            print(data.base64EncodedString(options: .lineLength64Characters))
        }
    }
    task.resume()
    semaphore.wait()
}
main.run()
