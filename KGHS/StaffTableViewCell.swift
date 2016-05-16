//
//  StaffTableViewCell.swift
//  KGHS
//
//  Created by Collin DeWaters and Taylor Courtney on 2/18/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit

class StaffTableViewCell: UITableViewCell {
    
    //properties of staff tableviewcell
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var affiliationLabel: UILabel!
    @IBOutlet weak var departmentChair: UIImageView!
    
    var cellContainsBGView = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
