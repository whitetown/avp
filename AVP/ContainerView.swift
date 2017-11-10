//
//  ContainerView.swift
//  AVP
//
//  Created by Sergey Chehuta on 09/11/2017.
//  Copyright © 2017 WhiteTown. All rights reserved.
//

import UIKit

class ContainerView: UIView {

    override func layoutSubviews()
    {
        super.layoutSubviews()

        if let sublayers = self.layer.sublayers
        {
            for sublayer in sublayers
            {
                sublayer.frame = self.bounds
            }
        }
    }


}
