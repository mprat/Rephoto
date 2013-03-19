//
//  PointCloudProcessing.cpp
//  Rephoto
//
//  Created by Michele Pratusevich on 3/1/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#include "PointCloudProcessing.h"

PointCloudProcessing::PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device, const char* resource_path){
    pointcloud_create(viewport_width, viewport_height,
					  video_width, video_height,
					  video_format,
					  device,
					  "f15df684-4a28-4afc-a31c-c4e6fb73969d");
    
    //for now set up image targets here. can always change to some other input later
    // Add images to look for (detection will not start until images are activated, though)
    std::string image_target_2_path = resource_path + std::string("image_target_2.model");
    
    pointcloud_add_image_target("image_2", image_target_2_path.c_str(), 0.3, -1);

}

PointCloudProcessing::~PointCloudProcessing(){
    pointcloud_destroy();
}

void PointCloudProcessing::on_accelerometer_update(float x, float y, float z, double timestamp){
    pointcloud_on_accelerometer_update(x, y, z, timestamp);
}

void PointCloudProcessing::on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp){
    pointcloud_on_device_motion_update(x, y, z, rot_x, rot_y, rot_z, g_x, g_y, g_x, timestamp);
}

//method for starting the point-cloud process of localizing to an image
bool PointCloudProcessing::start_match_to_image(){
    printf("Activating image target\n");
    pointcloud_reset();
    //TODO: figure out if we need this next line
    pointcloud_enable_map_expansion();
    pointcloud_activate_image_target("image_2");
    return true;
}

//method for starting slam map creation
bool PointCloudProcessing::start_slam(){
    pointcloud_state state = pointcloud_get_state();
//    std::cout<<"state = "<<state<<std::endl;
    if (state != POINTCLOUD_LOOKING_FOR_IMAGES && state != POINTCLOUD_TRACKING_IMAGES) {
		if (pointcloud_get_state() == POINTCLOUD_IDLE) {
			printf("Start initialization\n");
			pointcloud_start_slam();
		} else {
			printf("Resetting\n");
			pointcloud_reset();
		}
        return true;
	}
    return false;
}

void PointCloudProcessing::render_point_cloud(){
    pointcloud_state state = pointcloud_get_state();
//    std::cout<<"Rendering point cloud state = "<<state<<std::endl;
    if (state == POINTCLOUD_INITIALIZING ||
		state == POINTCLOUD_TRACKING_SLAM_MAP) {
//        std::cout<<"initializing or tracking slam map"<<std::endl;
        
        pointcloud_point_cloud* points = pointcloud_get_points();
		
        if (points) {			
            //TODO: render points in the point cloud
            
            
			pointcloud_destroy_point_cloud(points);
        }
//    } else if (state == POINTCLOUD_TRACKING_IMAGES) {
//        printf("tracking images\n");
    }
}

void PointCloudProcessing::frame_process(char *data, double timestamp){
    pointcloud_on_camera_frame(data, timestamp);
    render_point_cloud();
}