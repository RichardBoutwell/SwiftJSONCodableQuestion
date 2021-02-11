import Foundation
import PlaygroundSupport


// Simplified struct to hold color sample LAB data
struct CIELab: Codable {
    var L = 50.0
    var A = 0.0
    var B = 0.0
    
    init(lab: (Double, Double, Double)){
        L = lab.0
        A = lab.1
        B = lab.2
    }
    
}


struct QTPInkProfile: Codable {
    var QTPInkComponents : [QTPInkComponent]
}

struct QTPInkComponent : Codable {
    var name : String
    var ink : String
    var inkList : [String]
    
    var quad: [[Double]]
    var lab: [[Double]]
    var notes: String
    
    }


let jsonQTPInkComponent = """
{
    "name": "SomeInkComponent",
    "ink": "Gloss",
    "inkList": ["K","C","M"],
    "quad": [[0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8]],
    "lab": [[99.5,0.0,0.0],
            [50.5,0.0,0.0],
            [5.5,0.0,0.0]],
    "notes": "some notes text"
    
}
"""


let jsonQTPInkProfile = """
{
"QTPInkComponents" : {
"component" : {
    "name": "FirstInkComponent",
    "ink": "Gloss",
    "inkList": ["K","C","M"],
    "quad": [[0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8]],
    "lab": [[99.5,0.0,0.0],
            [50.5,0.0,0.0],
            [5.5,0.0,0.0]],
    "notes": "some notes text"
    },
"component" : {
    "name": "SecondInkComponent",
    "ink": "Gloss",
    "inkList": ["K","C","M"],
    "quad": [[0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8]],
    "lab": [[99.5,0.0,10.0],
            [50.5,0.0,10.0],
            [5.5,0.0,10.0]],
    "notes": "some notes text"
    },
"component" : {
    "name": "ThirdInkComponent",
    "ink": "Gloss",
    "inkList": ["K","C","M"],
    "quad": [[0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8],
             [0,1,2,3,4,5,6,7,8]],
    "lab": [[99.5,10.0,0.0],
            [50.5,10.0,0.0],
            [5.5,10.0,0.0]],
    "notes": "some notes text"
    }
    
}
}
"""

let jsonData = jsonQTPInkComponent.data(using: .utf8)
let decoder = JSONDecoder()

let inkComponent = try decoder.decode(QTPInkComponent.self, from: jsonData!)
var labArray = [CIELab]()

for l in inkComponent.lab {
    labArray.append(CIELab(lab: (l[0], l[1], l[2])))
}
for i in inkComponent.inkList {
    print("# \(i) Curve")
}

let jsonProfileData = jsonQTPInkProfile.data(using: .utf8)
let profileDecoder = JSONDecoder()
let profile = try decoder.decode(QTPInkProfile.self, from: jsonProfileData!)

/// MARK: Trying to using Core Data managed objects and archiver
let quadArray : [[Double]] = [[0.0, 5.0],[0.0, 0.0],[0.0, 10.0],[0.0, 20]]

let lab1 = CIELab(lab: (96, 0.1, 0.2))
let lab2 = CIELab(lab: (94, 0.2, 0.4))
let lab3 = CIELab(lab: (90, 0.1, 0.2))
let lab4 = CIELab(lab: (84, 0.2, 0.4))


class LabData : NSObject, NSSecureCoding, Codable {
    static var supportsSecureCoding: Bool = true

    var colorArray = [CIELab]()

    func encode(with aCoder: NSCoder) {
        aCoder.encode(colorArray, forKey: "colorArray")
    }

    required init?(coder aDecoder: NSCoder) {
        self.colorArray = aDecoder.decodeObject() as! [CIELab]
        super.init()
    }

    override init(){
        super.init()
    }
}


public class InkComponent : NSObject, Codable {
    public var name = "Curve Name"
           var labArray = [CIELab]()
    public var curveArray = [[Double]]()
    public var blackInkType = true

    init(blackInk: Bool, componentName: String) {
        blackInkType = true
        self.name = componentName
    }


    func encode(with aCoder: NSCoder) {
        aCoder.encode(labArray, forKey: "labArray")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(curveArray, forKey: "curveArray")
        aCoder.encode(blackInkType, forKey: "blackInkType")
    }

    required init?(coder aDecoder: NSCoder) {
        self.name = aDecoder.decodeObject() as! String
        self.labArray = aDecoder.decodeObject() as! [CIELab]
        self.curveArray = aDecoder.decodeObject() as! [[Double]]

        self.blackInkType = aDecoder.decodeObject() as! Bool
        super.init()
    }

    override init(){
        super.init()
    }

}

public class InkComponents : NSObject, Codable {

    public var profiles : [InkComponent]

    public func encode(with coder: NSCoder) {
        coder.encode(self.profiles, forKey: "profiles")
    }

    public required init?(coder: NSCoder) {
        self.profiles = (coder.decodeObject(forKey: "profiles") as? [InkComponent])!
    }

    init(profiles: [InkComponent]) {
        self.profiles = profiles
    }

}

var lab = LabData()
lab.colorArray = [lab1, lab2, lab3, lab4]


let component1 = InkComponent(blackInk: true, componentName: "black curve")
component1.labArray = lab.colorArray
component1.curveArray = quadArray

let cdProfile = InkComponents(profiles: [component1])

let profileArchiver = NSKeyedArchiver(requiringSecureCoding: true)
try! profileArchiver.encodeEncodable(profile, forKey: "InkComponents")

profileArchiver.finishEncoding()

let profileData = profileArchiver.encodedData
let unarchivedProfile = try! NSKeyedUnarchiver(forReadingFrom: profileData)
if unarchivedProfile.containsValue(forKey: "InkComponents") {
    let unarchivedData = unarchivedProfile.decodeDecodable(InkComponents.self, forKey: "InkComponents")
    let profile = unarchivedData?.profiles
    let ink1 = profile![0]
    let lab = ink1.labArray
    print(lab)
    let curve = ink1.curveArray
    print(curve)
}

let labArchiver = NSKeyedArchiver(requiringSecureCoding: true)

try! labArchiver.encodeEncodable(lab, forKey: "LabData")

labArchiver.finishEncoding()
//
let dataLab = labArchiver.encodedData
//
let unarchLab = try! NSKeyedUnarchiver(forReadingFrom: dataLab)
if unarchLab.containsValue(forKey: "LabData") {
    print("is data lab")
    let oldLab = unarchLab.decodeDecodable(LabData.self, forKey: "LabData")
    print(oldLab!.colorArray)
}






