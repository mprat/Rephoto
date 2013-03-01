//
//  PointCloudProcessing.h
//  Rephoto
//
//  Created by Michele Pratusevich on 3/1/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#ifndef __Rephoto__PointCloudProcessing__
#define __Rephoto__PointCloudProcessing__

#include <iostream>
#include "PointCloud.h"

class PointCloudProcessing {
public:
    PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device);
};

#endif /* defined(__Rephoto__PointCloudProcessing__) */
