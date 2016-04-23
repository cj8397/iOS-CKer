import UIKit
import MapKit
import CoreLocation
import PubNub

class MapViewController: UIViewController, MKMapViewDelegate, PNObjectEventListener {

    var mapView = MKMapView()
    var locations = [CLLocation]()
    var coordinateList = [CLLocationCoordinate2D]()
    var isFirstMessage = false
    var client: PubNub?
    var mapTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        client = PubNub.clientWithConfiguration(configuration)
        client?.addListener(self)
        client?.subscribeToChannels(["locTrack"], withPresence: false)
        
        mapView = MKMapView(frame: UIScreen.mainScreen().bounds)
        if #available(iOS 9.0, *) {
            mapView.showsCompass = true
        } else {
			
        }
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        self.view.addSubview(mapView)
        
        let centerPosition = UIButton(frame: CGRectMake((self.view.frame.width - 50), (self.view.frame.height - 50), 30, 30))
        centerPosition.setImage(UIImage(named: "location"), forState: .Normal)
        centerPosition.addTarget(self, action: "updateMapFrame", forControlEvents: .TouchUpInside)
        self.mapView.addSubview(centerPosition)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func client(client: PubNub, didReceiveMessage message: PNMessageResult) {
        
        if let receivedMessage = message.data.message as? [NSString : AnyObject] {
            if let lng : CLLocationDegrees = receivedMessage["lng"] as? Double, lat : CLLocationDegrees = receivedMessage["lat"] as? Double, alt : CLLocationDegrees = receivedMessage["alt"]  as? Double{
                
                let newLocation2D = CLLocationCoordinate2DMake(lat, lng)
                
                let newLocation = CLLocation(coordinate: newLocation2D, altitude: alt, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: NSDate())
                self.locations.append(newLocation)
                self.coordinateList.append(newLocation.coordinate)
                
                self.updateMapOverlay()
               
				
                if !isFirstMessage {
                    self.updateMapFrame()
                }
                
                // To update Marker Position
                self.updateCurrentPositionMarker(newLocation)
            }else {
                if let _ = receivedMessage["alertCode"] {
                    let alert = UIAlertController(title: "Alert", message: "The user has stopped sharing the location.", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                
                }
            }
            
        }
    }
    
    //Draws a polyline along users commute
    func updateMapOverlay() {
        // Build the overlay
        let line = MKPolyline(coordinates: &self.coordinateList, count: self.coordinateList.count)
        self.mapView.addOverlay(line)
        
    }
    
    //Renders polyline
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor(red: 70/255, green: 175/255, blue: 255/255, alpha: 1.0)
            polylineRenderer.lineWidth = 10
            return polylineRenderer
        }else {
            return MKPolylineRenderer()
        }
        
    }
    
    //To set map focus on the new position
    func updateMapFrame() {
        if let currentPosition = self.locations.last {
            let latitudeSpan = CLLocationDistance(500)
            let longitudeSpan = latitudeSpan
            let region = MKCoordinateRegionMakeWithDistance(currentPosition.coordinate, latitudeSpan, longitudeSpan)
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    //To update Marker Position
    func updateCurrentPositionMarker(location: CLLocation) {
        let currentPositionMarker = MKPointAnnotation()
        currentPositionMarker.coordinate = location.coordinate
        if !isFirstMessage {
            self.mapView.addAnnotation(currentPositionMarker)
            isFirstMessage = true
        }
            var existingAnnotations = self.mapView.annotations
      if existingAnnotations.count > 2 {
          existingAnnotations.removeLast()
           self.mapView.removeAnnotations(existingAnnotations)
       }
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.client?.unsubscribeFromAll()
    }

}
