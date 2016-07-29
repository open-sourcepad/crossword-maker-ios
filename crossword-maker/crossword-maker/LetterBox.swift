//
//  LetterBox.swift
//  CrossM
//
//  Created by Jonathan Andy Lim on 07/29/2016.
//  Copyright © 2016 SourcePad. All rights reserved.
//

import UIKit

class LetterBox: UITextField {
    
    var row: Int = 0
    var column: Int = 0
    var hiddenLetter = ""
    
    lazy var hintNumberLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRectMake(2.0, 2.0, 15.0, 15.0))
        label.textColor = UIColor.redColor()
        label.textAlignment = .Center
        
        return label
    }()
    
    //MARK: -
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.borderColor = UIColor.blackColor().CGColor
        self.layer.borderWidth = 1.0
        self.textAlignment = .Center
        
        self.addSubview(self.hintNumberLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
