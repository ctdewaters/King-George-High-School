//
//  EventTableViewCell.swift
//  KGHS
//
//  Created by Collin DeWaters and Taylor Courtney on 2/5/15.
//  Copyright (c) 2015 CDWApps. All rights reserved.
//

import UIKit

class EventTableViewCell: UITableViewCell {
    
    //Properties of eventstableviewcell
    
    @IBOutlet weak var titleLabel: MarqueeLabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryLabel: UILabel!
    
    var cellContainsBGView = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
