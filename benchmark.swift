import Foundation

struct FlutterAnnotation {
    var id: String
}

var annotations: [FlutterAnnotation] = []
for i in 0..<10000 {
    annotations.append(FlutterAnnotation(id: "id_\(i)"))
}

// Ensure the random seed is reproducible for a fair comparison, though time based is ok
let startArray = Date()
var count = 0
for i in 0..<1000 {
    let id = "id_\(i * 10)"
    let found = annotations.filter { $0.id == id }.first
    if found != nil { count += 1 }
}
let endArray = Date()

print("Array filter O(N) time: \(endArray.timeIntervalSince(startArray)) seconds for 1000 lookups in 10000 items")

var annotationsMap: [String: FlutterAnnotation] = [:]
for a in annotations {
    annotationsMap[a.id] = a
}

let startDict = Date()
count = 0
for i in 0..<1000 {
    let id = "id_\(i * 10)"
    let found = annotationsMap[id]
    if found != nil { count += 1 }
}
let endDict = Date()

print("Dict lookup O(1) time: \(endDict.timeIntervalSince(startDict)) seconds for 1000 lookups in 10000 items")
