//
//  CoinManager.swift
//  ByteCoin
//


import Foundation
//By convention, Swift protocols are usually written in the file that has the class/struct which will call the
//delegate methods, i.e. the CoinManager.

protocol CoinManagerDelegate {
    func didUpdatePrice(price: String, currency: String)
    func didFailWithError(error: Error)
}

struct CoinManager {
    
    //Created an optional delegate that will have to implement the delegate methods that we will notify when we have updated the price.
    var delegate: CoinManagerDelegate?
    
    let baseURL = "https://rest.coinapi.io/v1/exchangerate/BTC"
    
    // Dynamically fetch the API key from Secrets.plist
    var apiKey: String? {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dictionary = NSDictionary(contentsOfFile: path) as? [String: Any] {
            return dictionary["API_KEY"] as? String
        }
        return nil
    }
    
    //let apiKey = "API_KEY_HERE"

    let currencyArray = ["AUD", "BRL","CAD","CNY","EUR","GBP","HKD","IDR","ILS","INR","JPY","MXN","NOK","NZD","PLN","RON","RUB","SEK","SGD","USD","ZAR","TRY"]
    
    func getCoinPrice(for currency: String) {
        
        // Safely unwrap the API key
        guard let apiKey = apiKey else {
            print("API Key not found.")
            return
        }
        //Use String concatenation to add the selected currency at the end of the baseURL along with the API key.
        let urlString = "\(baseURL)/\(currency)?apikey=\(apiKey)"
        
        //Use optional binding to unwrap the URL that's created from the urlString
        if let url = URL(string: urlString) {
            
            //Create a new URLSession object with default configuration.
            let session = URLSession(configuration: .default)
            
            //Create a new data task for the URLSession
            let task = session.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                //Format the data we got back as a string to be able to print it.
                if let safeData = data {
                    if let bitcoinPrice = self.parseJSON(safeData){
                        //Optional: round the price down to 2 decimal places.
                        let priceString = String(format: "%.2f", bitcoinPrice)
                        
                        //Call the delegate method in the delegate (ViewController) and
                        //pass along the necessary data.
                        self.delegate?.didUpdatePrice(price: priceString, currency: currency)
                    }
                }
                
            }
            //Start task to fetch data from bitcoin average's servers.
            task.resume()
        }
    }
    
    func parseJSON(_ data: Data) -> Double? {
        let decoder = JSONDecoder()
        do{
            
            //try to decode the data using the CoinData structure
            let decodedData = try decoder.decode(CoinData.self, from: data)
            
            //Get the last property from the decoded data.
            let lastPrice = decodedData.rate
            print(lastPrice)
            return lastPrice
            
        } catch {
            //Catch and print any errors.
            print(error)
            return nil
        }
    }
    
        
}

