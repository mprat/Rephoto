//
//  PointCloudProcessing.cpp
//  Rephoto
//
//  Created by Michele Pratusevich on 3/1/13.
//  Copyright (c) 2013 Michele Pratusevich. All rights reserved.
//

#include "PointCloudProcessing.h"
#include <algorithm>

//attribute index
enum {
    ATTRIB_POINTPOS
};

PointCloudProcessing::PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device, const char* resource_path, GLint model_view_projection_uniform){
    pointcloud_create(viewport_width, viewport_height,
					  video_width, video_height,
					  video_format,
					  device,
					  "f15df684-4a28-4afc-a31c-c4e6fb73969d");
    
//    //for now set up image targets here. can always change to some other input later
//    // Add images to look for (detection will not start until images are activated, though)
//    std::string image_target_2_path = resource_path + std::string("image_target_2.model");
//    pointcloud_add_image_target("image_2", image_target_2_path.c_str(), 0.3, -1);
//    

    setup_graphics();
    
    mvp_uniform = model_view_projection_uniform;
}

PointCloudProcessing::~PointCloudProcessing(){
    pointcloud_destroy();
}

void PointCloudProcessing::setup_graphics(){
    pointcloud_context context = pointcloud_get_context();
    
    //TODO: add ui_scale_scale factor?
    glViewport(0, 0, context.viewport_width, context.viewport_height);
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
    
    //if true and the screen goes really dark, then we really are rendering openGL from here
    if (false){
        glClearColor(0, 0, 0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
    }
        
    pointcloud_state state = pointcloud_get_state();
//    std::cout<<"Rendering point cloud state = "<<state<<std::endl;
    if (state == POINTCLOUD_INITIALIZING ||
		state == POINTCLOUD_TRACKING_SLAM_MAP) {
//        std::cout<<"initializing or tracking slam map"<<std::endl;
        
        pointcloud_point_cloud* points = pointcloud_get_points();
		
        if (points) {
            glEnable(GL_BLEND);
            //do I change this to GL_SRC_ONE_MINUS_ALPHA? it blinks black and white what the heck do I know
            glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA);
            
            //model view projection matrix
            Matrix4x4 mvp = Matrix4x4(projection_matrix.data) * Matrix4x4(camera_matrix.data);
//            mvp.print();
//            std::cout<<*((float*)mvp)<<std::endl;
            glUniformMatrix4fv(mvp_uniform, 1, GL_FALSE, (float*)mvp);
            
            
            //TODO: add points to the buffer (_vertexBuffer in the graphicsSingleton...)?
            glBufferData(GL_ARRAY_BUFFER, 3*sizeof(float)*(std::min(5012, (int)points->size)), (float *)points->points, GL_DYNAMIC_DRAW);
            glEnableVertexAttribArray(ATTRIB_POINTPOS);
            glDrawArrays(GL_POINTS, 0, points->size);
            
			pointcloud_destroy_point_cloud(points);
        }
        
//        glDisableVertexAttribArray(ATTRIB_POINTPOS);
//    } else if (state == POINTCLOUD_TRACKING_IMAGES) {
//        printf("tracking images\n");
    }
}

void PointCloudProcessing::frame_process(char *data, double timestamp){
    pointcloud_on_camera_frame(data, timestamp);
    
    camera_matrix = pointcloud_get_camera_matrix();
//	Matrix4x4 cm = Matrix4x4(camera_matrix.data);
//    std::cout<<"camera matrix"<<std::endl;
//    cm.print();
    
	// Calculate the camera projection matrix (with given near and far clipping planes)
	projection_matrix = pointcloud_get_frustum(0.1, 100);
//    Matrix4x4 pm = Matrix4x4(projection_matrix.data);
//    std::cout<<"projection matrix"<<std::endl;
//    pm.print();

    render_point_cloud();
}