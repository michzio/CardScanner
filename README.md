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
 CollectionView(
                layout: createLayout(),
                sections: sections,
                items: [
                    .feature : Item.featureItems,
                    .categories : Item.categoryItems
                ],
                supplementaryKinds: [UICollectionView.elementKindSectionHeader, UICollectionView.elementKindSectionFooter],
                supplementaryContent: { kind, indexPath, section, item in
                    switch kind {
                    case UICollectionView.elementKindSectionHeader:
                        return AnyView(Text("Header").font(.system(size: indexPath.section == 0 ? 30 : 16)))
                    case UICollectionView.elementKindSectionFooter:
                        return AnyView(Text("Footer"))
                    default:
                        return AnyView(EmptyView())
                    }
                },
            content: { indexPath, item in
                let section = sections[indexPath.section]
                AnyView(
                    ZStack {
                        section == .feature ? Color.green : Color.red

                        Text("\(section.rawValue) (\(indexPath.section), \(indexPath.row))")
                            .padding(16)
                            .foregroundColor(Color.white)
                    }
                )
            }
)
```

![alt text](cardscanner-test.gif)
