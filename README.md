# CardScanner

Payment card scanning tool 

# Usage - Cocoapods 

```
pod 'Card_Scanner'
```

# Usage - Swift Package Manager

Once you have your Swift package set up, adding CardScanner as a dependency is as easy as adding it to the dependencies value of your Package.swift.

```
dependencies: [
    .package(url: "https://github.com/michzio/CardScanner.git", .upToNextMajor(from: "0.1.0"))
]
```


# How to use 

```
CardScanner(firstNameSuggestion: "Tim", lastNameSuggestion: "Cook") { cardNumber, expiryDate, holder in
            self.cardNumber = cardNumber 
            self.holder = holder
            self.expiryDate = expiryDate
}
```

![alt text](cardscanner-test.gif)
