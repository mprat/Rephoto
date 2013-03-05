//
//  PointCloudProcessing.cpp
//  Rephoto
//
//  Created by Michele Pratusevich on 3/1/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#include "PointCloudProcessing.h"

PointCloudProcessing::PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device){
    pointcloud_create(viewport_width, viewport_height,
					  video_width, video_height,
					  video_format,
					  device,
					  "f15df684-4a28-4afc-a31c-c4e6fb73969d");
}

void PointCloudProcessing::on_accelerometer_update(float x, float y, float z, double timestamp){
    pointcloud_on_accelerometer_update(x, y, z, timestamp);
}

void PointCloudProcessing::on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp){
    pointcloud_on_device_motion_update(x, y, z, rot_x, rot_y, rot_z, g_x, g_y, g_x, timestamp);
}

//method for starting the point-cloud process of localizing to an image
bool PointCloudProcessing::on_start_match_to_image(double x, double y){
    return true;
}

void PointCloudProcessing::render_point_cloud(){
    
}