//
//  EditInfoViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 5/4/22.
//

import UIKit

class EditInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate{

    
    //store the courses
    private var courses: [String] = []
    
    //outlets to be set from db
    @IBOutlet weak var coursesTableView: UITableView!
    @IBOutlet weak var courseTitle: UITextField!
    
    //add class to the table view and courses array
    @IBAction func addClassClicked(_ sender: Any) {
        //get the course title from the field
        let courseTitleName = courseTitle.text
        //if it isnt empty
        courses.append(courseTitleName!)
        //erase the content
        courseTitle.text = ""
        //reload the table
        coursesTableView.reloadData()
    }
    
    //reload the table on appear
    override func viewDidAppear(_ animated: Bool) {
        initInformation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize the text fields
        //initialize the table view
        coursesTableView.delegate = self
        coursesTableView.dataSource = self
    }
    
    //save the changes to the database
    @IBAction func saveChangesClicked(_ sender: Any) {
        updateData()
    }
    
    //get the user data and populate the fields and the course list
    private func initInformation(){
        
        //get the current user email (safe)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        //set the location and handle hte completion
        DatabaseManager.shared.getUserInformationAsStruct(safeEmailAddress: currentSafeEmail, completion: { result in
                switch result{
                
                //call was good
                case.success(let data):
                    
                    //get the user data from the completion handldeer
                    guard let pulledCourses = data as? [String] else {
                        return
                    }
                    
                    //save the data
                    self.courses = [] //erase the data
                    self.courses = pulledCourses //set the data
                    
                    //refresh the table
                    self.coursesTableView.reloadData()
                        
                //call was bad
                case.failure(let error):
                    print("Failed to read data with error \(error)")
                }
        })
    }
    
    //writes all the data back to firebase and goes back to profile
    private func updateData(){
        //get the current user email (safe)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        //update the database
        DatabaseManager.shared.updateUserCourses(safeEmailAddress: currentSafeEmail, courses: courses, completion: { result in
            switch result{
            //call was good
            case.success(let data):
                print("User courses updated successfully! \(data)")
            //call was bad
            case.failure(let error):
                print("Failed to read data with error \(error)")
            }
        })
    }
    
    //set up the table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }
    
    //set up the cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        
        //set the cell text to be the name
        cell.textLabel?.text = "\(courses[indexPath.row])"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
           print("Deleted")
           self.courses.remove(at: indexPath.row)
            coursesTableView.reloadData()
        }
    }

}
