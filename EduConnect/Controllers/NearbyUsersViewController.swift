//
//  NearbyUsersViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 5/2/22.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseStorage
import SDWebImage

//nearby user object
struct NearbyUser{
    var name: String
    var safeEmail: String
    var major: String
    var profilePic: String
}

class NearbyUsersViewController: UIViewController, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate{
    
    //Core Location Manager
    let locationManager = CLLocationManager()
    
    //Nearby Users List
    //array of nearby user
    var nearbyUsers: [NearbyUser] = []
    var currentX: Double = 0.0
    var currentY: Double = 0.0

    //displays the current x and y coordinate
    @IBOutlet weak var currentCoordinatesLabel: UILabel!
    
    //table view outlet
    @IBOutlet weak var tableView: UITableView!
    
    //rows in the table
    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int{
        //number of current users
        return nearbyUsers.count;
        //return 10; //hardcoded for now
    }
    
    //cell format
    public func tableView(_ tableView: UITableView,
    cellForRowAt indexPath: IndexPath)
    -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        
        //set the cell text to be the name
        cell.textLabel?.text = "\(nearbyUsers[indexPath.row].name) | Major:\(nearbyUsers[indexPath.row].major)"
        
        return cell
    }
    
    //onclick of a nearby user, open up their information
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "otherProfileView") as! OtherProfileViewController
        nextViewController.otherUserSafeEmail = nearbyUsers[indexPath.row].safeEmail
        self.present(nextViewController, animated:true, completion:nil)
    }
    
    //add on click of cell - will open profile segue
    
    //on appear get the users
    override func viewDidAppear(_ animated: Bool) {
        print("DEBUG: Getting nearby users!")
        
        //get the current user email (safe)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        //get the nearby users from the database
        DatabaseManager.shared.getNearbyUsers(emailAddress: currentSafeEmail, x: currentX, y: currentY, completion: { [self] result in
            switch result{
            
            //call was good
            case.success(let data):
                
                //get the nearby user list from the completion handldeer
                guard let nearbyUsersDB = data as? [NearbyUser] else {
                    return
                }
                
                //populate the nearby users list
                self.nearbyUsers = nearbyUsersDB
                
                //update the table view
                self.tableView.reloadData();
            
            //call was bad
            case.failure(let error):
                print("Failed to read data with error \(error)")
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            print("START UPDATING LOCATION")
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        //table view setup
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //called when updating location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        print("location changed");
        
        //get the location values
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        //update the database
        
        //get the current user email (safe)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        //get the users current x and y coordinate using Core Location
        
        let updatedLat = locValue.latitude
        let updatedLong = locValue.longitude
        
        //set the location and handle hte completion
        DatabaseManager.shared.setLocation(emailAddress: currentSafeEmail, x: updatedLat, y: updatedLong, completion: { result in
                switch result{
                
                //call was good
                case.success(let data):
                    
                    //get the user data from the completion handldeer
                    guard let userData = data as? [String: Any],
                    let newX = userData["x"] as? Double,
                    let newY = userData["y"] as? Double else {
                        return
                    }
                    
                    print("INSERTED - x: \(newX), y: \(newY)")
                    
                    self.currentX = newX;
                    self.currentY = newY;
                    self.currentCoordinatesLabel.text = "x: \(newX), y: \(newY)"
                    
                    //now that I have the new coordinates updated, I obviously want to update the nearby users without having to click the button
                
                //call was bad
                case.failure(let error):
                    print("Failed to read data with error \(error)")
                }
        })
        
        //update the UI
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    //refresh the nearby users list
    @IBAction func refreshUsers(_ sender: Any) {
        
        print("DEBUG: Getting nearby users!")
        
        //get the current user email (safe)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        //get the nearby users from the database
        DatabaseManager.shared.getNearbyUsers(emailAddress: currentSafeEmail, x: currentX, y: currentY, completion: { [self] result in
            switch result{
            
            //call was good
            case.success(let data):
                
                //get the nearby user list from the completion handldeer
                guard let nearbyUsersDB = data as? [NearbyUser] else {
                    return
                }
                
                //populate the nearby users list
                self.nearbyUsers = nearbyUsersDB
                
                //update the table view
                self.tableView.reloadData();
            
            //call was bad
            case.failure(let error):
                print("Failed to read data with error \(error)")
            }
        })
    }
    
}
