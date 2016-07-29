//
//  ViewController.swift
//  crossword-maker
//
//  Created by Jonathan Andy Lim on 07/29/2016.
//  Copyright © 2016 SourcePad. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    var words = ["apple", "banana", "peaches", "helicopter", "macbook", "iphone"]
    var grid: Dictionary<NSIndexPath,String> = [:]
    var letterBoxes: Dictionary<NSIndexPath,LetterBox> = [:]
    var across: Dictionary<String,NSIndexPath> = [:]
    var downward: Dictionary<String,NSIndexPath> = [:]
    
    var wordsHint: Dictionary<String,String> = [:]
    var alert: UIAlertController?
    
    //MARK: - Lazy variables
    private lazy var addAnotherButton: UIButton = {
        let button: UIButton = UIButton(frame: CGRectMake(60.0, 80.0, 150.0, 40.0))
        button.setTitle("Add Another", forState: .Normal)
        button.addTarget(self, action: #selector(ViewController.addAnotherButtonAction(_:)), forControlEvents: .TouchUpInside)
        button.backgroundColor = UIColor(red: 0, green: 0.5, blue: 1.0, alpha: 1.0)
        button.layer.cornerRadius = 10.0
        
        return button
    }()
    
    private lazy var acrossHintsTableView: UITableView = {
        let tableview: UITableView = UITableView(frame: CGRectMake(0, self.view.bounds.width, self.view.bounds.width/2, self.view.bounds.height-self.view.bounds.width), style: .Plain)
        tableview.tag = 100
        tableview.registerClass(UITableViewCell.self, forCellReuseIdentifier: "AcrossCell")
        tableview.delegate = self
        tableview.dataSource = self
        
        return tableview
    }()

    private lazy var downwardHintsTableView: UITableView = {
        let tableview: UITableView = UITableView(frame: CGRectMake(self.view.bounds.width/2, self.view.bounds.width, self.view.bounds.width/2, self.view.bounds.height-self.view.bounds.width), style: .Plain)
        tableview.tag = 101
        tableview.registerClass(UITableViewCell.self, forCellReuseIdentifier: "DownwardCell")
        tableview.delegate = self
        tableview.dataSource = self
        
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        alert = UIAlertController(title: "New Crossword", message: "Type your word and hint.\n\n\n", preferredStyle: .Alert)
        let doneAction = UIAlertAction(title: "Done", style: .Default) { (action) in
            self.saveWordsAndHint()
            
            let dict = self.wordsHint as NSDictionary
            let allKeys = dict.allKeys as! Array<String>
            self.sendWords(allKeys, completed: { 
                self.layoutWordsAndHints()
            })
        }
        alert!.addAction(doneAction)
        
        alert!.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Word"
            textField.tag = 0
        }
        alert!.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Hint"
            textField.tag = 1
        }
        
        self.presentViewController(alert!, animated: true) { 
            self.alert!.view.addSubview(self.addAnotherButton)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Private methods
    private func configureView() {
        words.sortInPlace({ $0.characters.count > $1.characters.count })
        
        layoutTextBoxes(15, columns: 15)
        
        self.view.addSubview(self.acrossHintsTableView)
        self.view.addSubview(self.downwardHintsTableView)
    }
    
    private func saveWordsAndHint() {
        let wordTextfield = self.alert!.textFields![0]
        let hintTextfield = self.alert!.textFields![1]
        
        if wordTextfield.text!.isEmpty || hintTextfield.text!.isEmpty {
            return
        }
        
        self.wordsHint[wordTextfield.text!] = hintTextfield.text!
        
        print("Saved \(wordTextfield.text!): \(hintTextfield.text!)")
        
        wordTextfield.text = ""
        hintTextfield.text = ""
        wordTextfield.becomeFirstResponder()
    }
    
    private func layoutTextBoxes(rows: Int, columns: Int) {
        let width = self.view.bounds.width/CGFloat(columns)
        let height = width
        
        for row in 0..<rows {
            for column in 0..<columns {
                let x = CGFloat(column) * width
                let y = CGFloat(row) * height
                let letterBox = LetterBox(frame: CGRectMake(x, y, width, height))
                letterBox.column = column
                letterBox.row = row
                
                let indexPath = NSIndexPath(forRow: row, inSection: column)
                self.letterBoxes[indexPath] = letterBox
                
                self.view.addSubview(letterBox)
            }
        }
    }

    func layoutWordsAndHints() {
        for (indexPath, letter) in self.grid {
            if let letterbox = self.letterBoxes[indexPath] {
                letterbox.hiddenLetter = letter
                letterbox.text = letter
                if letterbox.hiddenLetter == "_" || letterbox.hiddenLetter == "" {
                    letterbox.backgroundColor = UIColor.blackColor()
                } else {
                    letterbox.backgroundColor = UIColor.whiteColor()
                }
            }
        }
        
        self.acrossHintsTableView.reloadData()
        self.downwardHintsTableView.reloadData()
    }
    
    
    //MARK: - Button actions
    func addAnotherButtonAction(sender: AnyObject) {
        saveWordsAndHint()
    }
    
    //MARK: - API
    func sendWords(words: Array<String>, completed: () -> Void) {
        var params: Dictionary<String,AnyObject> = [:]
        for index in 0..<words.count {
            params["words[\(index)]"] = words[index]
        }
        Alamofire.request(.POST, "https://crossword-maker.herokuapp.com/api/v1/puzzles", parameters: params, headers: nil)
        .responseJSON { response in
            print(response.response) // URL response
            print(response.result)   // result of response serialization
            
            if let JSON = response.result.value {
                print("JSON: \(JSON)")
                
                self.parseJSON(JSON, completed: { 
                    completed()
                })
            }
        }
    }
    
    func parseJSON(json: AnyObject, completed: () -> Void) {
        let dict = json as! Dictionary<String,AnyObject>
        if let dataDict = dict["data"] as? Dictionary<String,AnyObject> {
            if let gridDict = dataDict["grid"] as? Dictionary<String,AnyObject> {
                if let cells = gridDict["cells"] as? Array<NSDictionary> {
                    for cell in cells {
                        let x = cell["x"]!.integerValue
                        let y = cell["y"]!.integerValue
                        let indexPath = NSIndexPath(forRow: y, inSection: x)
                        if let letter = cell["letter"] as? String{
                            self.grid[indexPath] = letter
                        }
                    }
                }
            }
            
            // ACROSS
            if let cellsArray = dataDict["horizontal_words_on_grid"] as? Array<NSDictionary> {
                for cell in cellsArray {
                    if let cellDict = cell["cell"] as? NSDictionary {
                        let x = cellDict["x"]!.integerValue
                        let y = cellDict["y"]!.integerValue
                        let indexPath = NSIndexPath(forRow: y, inSection: x)
                        if let word = cell["word"] as? String {
                            self.across[word] = indexPath
                        }
                    }

                }
            }
            
            // DOWNWARD
            if let cellsArray = dataDict["vertical_words_on_grid"] as? Array<NSDictionary> {
                for cell in cellsArray {
                    if let cellDict = cell["cell"] as? NSDictionary {
                        let x = cellDict["x"]!.integerValue
                        let y = cellDict["y"]!.integerValue
                        let indexPath = NSIndexPath(forRow: y, inSection: x)
                        if let word = cell["word"] as? String {
                            self.downward[word] = indexPath
                        }
                    }
                }
            }
        }
        
        completed()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Across
        if tableView.tag == 100 {
            return self.across.count
        } else {
            return self.downward.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // Across
        if tableView.tag == 100 {
            let cell = tableView.dequeueReusableCellWithIdentifier("AcrossCell", forIndexPath: indexPath)
            cell.selectionStyle = .None
            
            let acrossDict = across as NSDictionary
            let allKeys = acrossDict.allKeys
            
            if let word = allKeys[indexPath.row] as? String {
                if let hint = wordsHint[word] {
                    cell.textLabel?.text = "\(indexPath.row + 1) : \(hint)"
                    
                    // Put number in grid
                    if let letterIndexPath = across[word] {
                        if let letterbox = self.letterBoxes[letterIndexPath] {
                            letterbox.hintNumberLabel.text = "\(indexPath.row + 1)"
                        }
                    }
                }
            }
            
            return cell

        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("DownwardCell", forIndexPath: indexPath)
            cell.selectionStyle = .None
            
            let downDict = downward as NSDictionary
            let allKeys = downDict.allKeys
            
            if let word = allKeys[indexPath.row] as? String {
                if let hint = wordsHint[word] {
                    cell.textLabel?.text = "\(indexPath.row + 1) : \(hint)"
                    
                    // Put number in grid
                    if let letterIndexPath = downward[word] {
                        if let letterbox = self.letterBoxes[letterIndexPath] {
                            letterbox.hintNumberLabel.text = "\(indexPath.row + 1)"
                        }
                    }
                }
            }

            return cell
        }
        

    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if tableView.tag == 100 {
            return "Down"
        } else {
            return "Across"
        }
    }
}
