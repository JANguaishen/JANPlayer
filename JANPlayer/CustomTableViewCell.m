//
//  CustomTableViewCell.m
//  video
//
//  Created by 纪奥宁 on 2017/6/13.
//  Copyright © 2017年 纪奥宁. All rights reserved.
//

#import "CustomTableViewCell.h"
#import "Masonry.h"

@implementation CustomTableViewCell
{
    UILabel *nameLabel;
    UIButton *playbutton;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self)
    {
        self.backgroundColor = [UIColor lightGrayColor];
        [self createUI];
    }
    return self;
}
- (void)createUI
{
    nameLabel  = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 100, 30)];
    [self addSubview:nameLabel];
    
    playbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playbutton setImage:[UIImage imageNamed:@"Start.png"] forState:UIControlStateNormal];
    [playbutton addTarget:self action:@selector(playButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:playbutton];
    [playbutton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
}
- (void)setValueWithData:(NSDictionary *)data AndIndexPath:(NSIndexPath *)indexPath
{
    nameLabel.text = data[@"name"];
}

- (void)playButtonClick:(UIButton *)button
{
    
}
@end
