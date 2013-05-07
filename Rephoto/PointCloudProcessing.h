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
#include <algorithm>
#include <string>
#include "PointCloud.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
//#include "Matrix4x4.h"
#include "Pose.h"

class PointCloudProcessing {
public:
    PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device, const char* resource_path, GLuint prog);
    ~PointCloudProcessing();
    
    void on_accelerometer_update(float x, float y, float z, double timestamp);
	void on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp);
    
    void frame_process(char *data, double timestamp);
    bool start_slam();
    
    void render_point_cloud();
    void save_slam_map(std::string filename);
    void load_slam_filename(std::string filename);
    void set_desired_camera_pose(Matrix4x4 pose);
    void start_align();
    float arrows();
    
    bool aligning();
    
protected:
    pointcloud_matrix_4x4 projection_matrix;
	pointcloud_matrix_4x4 camera_matrix;
    Pose current_camera_pose;
    Pose desired_camera_pose;
    //Vector3D desired_object_loc;
    
private:
    void setup_graphics();
    void send_mvp_matrix();
    
    GLuint program;
    bool aligning_to_old;
    
    GLuint mvp_uniform;
    GLuint color_uniform;
};

#endif /* defined(__Rephoto__PointCloudProcessing__) */
