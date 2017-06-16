//
//  CustomTableViewCell.h
//  video
//
//  Created by 纪奥宁 on 2017/6/13.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell

- (void)setValueWithData:(NSDictionary *)data AndIndexPath:(NSIndexPath *)indexPath;

@end
