//
//  ViewController.swift
//  ARKitDraw
//
//  Created by Felix Lapalme on 2017-06-07.
//  Copyright © 2017 Felix Lapalme. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreLocation
import OpenGLES
import Alamofire

class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var previousPoint: SCNVector3?
    @IBOutlet weak var button: UIButton!
    var lineColor = UIColor.blue
    let locationManager = CLLocationManager()
    var startingPoint = 0
    var long = 0.0
    var lat = 0.0
    var firstlong = 0.0
    var firstlat = 0.0
    var pointArray = [[String : Any]]()
    var buttonHighlighted = false
    var x = 0
    var flag=1

    override func viewDidLoad() {
        super.viewDidLoad()
        self.startingPoint = 0;
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/world.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.buttonHighlighted = self.button.isHighlighted
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        
        // request nearby
        let reqURL = "https://nwhacks2019-graffitiar.azurewebsites.net/drawing/nearby?longitude=\(long)&latitude=\(lat)"
        
        guard let pointOfView = sceneView.pointOfView else { return }
        
        let mat = pointOfView.transform
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let currentPosition = pointOfView.position + (dir * 0.1)
        if(flag == 1 && long != 0 && lat != 0 )
        {
            var points = [[String : Any]]()

            Alamofire.request(reqURL)
            .responseJSON { response in
                if let json = response.result.value {
                    print("JSON: \(json)")
                    //print("xxx")
                    var arr = json as! [Any]
                    for item in arr  {
                            var itemx = item as! [String : Any]
                            points = itemx["points"] as! [[String : Any]]
                            let longFetched = itemx["longitude"] as! Double
                            let latFetched = itemx["latitude"] as! Double
                            let deltaLong =  longFetched - self.long
                            let deltaLat =  latFetched - self.lat
                            print("deltaLong")
                            print(deltaLong)
                            print("deltaLat")
                            print(deltaLat)
                            let xdiff = deltaLong*(111111.0 * cos(deltaLat * Double.pi / 180))
                            let zdiff = deltaLat*(111111.0)
                            var index = 0
                                    print(points[index]["x"])
                            while index < points.count-1 {
                                let first = SCNVector3.init(points[index]["x"] as! Double + xdiff, points[index]["y"] as! Double, points[index]["z"] as! Double + zdiff)
                                let second = SCNVector3.init(points[index+1]["x"] as! Double + xdiff , points[index+1]["y"] as! Double, points[index+1]["z"] as! Double + zdiff  )
                                let twoPointsNode1 = SCNNode();
                                scene.rootNode.addChildNode(twoPointsNode1.buildLine(
                                    from: first, to: second, radius: 0.005, color: .cyan))
                                index = index + 1
                            }
                            
                        
                        }
                    }
                }
             flag = 0
            }
        
        
        if buttonHighlighted {
            if startingPoint == 0 {
                firstlong = long
                firstlat = lat
                print(firstlong)
                print(firstlat)
                startingPoint = 1
            }
          
            if let previousPoint = previousPoint {
//                let line = lineFrom(vector: previousPoint, toVector: currentPosition)
//                let lineNode = SCNNode(geometry: line)
//                lineNode.geometry?.firstMaterial?.diffuse.contents = lineColor
//                sceneView.scene.rootNode.addChildNode(lineNode)
                
                let twoPointsNode1 = SCNNode();
                scene.rootNode.addChildNode(twoPointsNode1.buildLine(
                    from: previousPoint, to: currentPosition, radius: 0.005, color: .cyan))
            }
            let point: [String: Any] =
                [
                    "x": currentPosition.x as! Float,
                    "y": currentPosition.y as! Float,
                    "z": currentPosition.z as! Float,
                    ]
            pointArray.append(point)
            
            x = 1
        }
        else {
            if (x == 1){
                print("BUTTON LEFT")
                x = 0
                startingPoint = 0
                // send request
                let PostURL = "https://nwhacks2019-graffitiar.azurewebsites.net/drawings"
                let parameters: Parameters = [
                    "longitude": firstlong,
                    "latitude": firstlat, 
                    "points": pointArray
                ]
                Alamofire.request(PostURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)

                print(parameters)
            }
        }
        previousPoint = currentPosition
        //let prev = previousPoint.worldPosition
       
        glLineWidth(200)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
            long = locValue.longitude
            lat = locValue.latitude
        //print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
        
    }
    
    
}
