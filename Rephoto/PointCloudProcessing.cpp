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

//uniform index
enum{
    UNIFORM_MODELVIEWPROJECTION,
    UNIFORM_POINTCOLOR,
    NUM_UNIFORMS
};

PointCloudProcessing::PointCloudProcessing(int viewport_width, int viewport_height, int video_width, int video_height, pointcloud_video_format video_format, const char* device, const char* resource_path, GLuint prog){
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
    program = prog;
    aligning_to_old = false;
    
    mvp_uniform = glGetUniformLocation(program, "modelViewProjectionMatrix");
    color_uniform = glGetUniformLocation(program, "pointcolor");
}

PointCloudProcessing::~PointCloudProcessing(){
    pointcloud_destroy();
}

void PointCloudProcessing::setup_graphics(){
    pointcloud_context context = pointcloud_get_context();
    
    //TODO: add ui_scale_scale factor?
    glViewport(0, 0, context.viewport_width, context.viewport_height);
    
    //clear graphics buffers
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    glDisableVertexAttribArray(ATTRIB_POINTPOS);
    
    aligning_to_old = false;
}

void PointCloudProcessing::on_accelerometer_update(float x, float y, float z, double timestamp){
    pointcloud_on_accelerometer_update(x, y, z, timestamp);
}

void PointCloudProcessing::on_device_motion_update(float x, float y, float z, float rot_x, float rot_y, float rot_z, float g_x, float g_y, float g_z, double timestamp){
    pointcloud_on_device_motion_update(x, y, z, rot_x, rot_y, rot_z, g_x, g_y, g_x, timestamp);
}

//method for starting slam map creation
bool PointCloudProcessing::start_slam(){
    pointcloud_state state = pointcloud_get_state();
//    std::cout<<"state = "<<state<<std::endl;
    if (state != POINTCLOUD_LOOKING_FOR_IMAGES && state != POINTCLOUD_TRACKING_IMAGES) {
		if (pointcloud_get_state() == POINTCLOUD_IDLE) {
			printf("Start initialization\n");
			pointcloud_start_slam();
            setup_graphics();
		} else {
			printf("Resetting\n");
			pointcloud_reset();
            setup_graphics();
		}
        return true;
	}
    return false;
}

void PointCloudProcessing::save_slam_map(std::string filename){
    pointcloud_state state = pointcloud_get_state();
    // only save a map when you are tracking the map
    if (state == POINTCLOUD_TRACKING_SLAM_MAP){
        pointcloud_save_current_map(filename.c_str());
    } else {
        std::cout<<"can't save map if it's not tracked"<<std::endl;
    }
}

void PointCloudProcessing::load_slam_filename(std::string filename){
    pointcloud_load_map(filename.c_str());
//    std::cout<<"loaded map from file!"<<std::endl;
    
    aligning_to_old = true;
}

void PointCloudProcessing::set_desired_camera_pose(Matrix4x4 pose){
    desired_camera_pose = Pose(pose);
    Vector3D desired_object_loc = desired_camera_pose.getObjectLocation();
    
    //debug POSE
//    std::cout<<"desired camera pose"<<std::endl;
//    desired_camera_pose.print();
    std::cout<<"desired object location"<<std::endl;
    desired_object_loc.print();
}

void PointCloudProcessing::start_align(){
    aligning_to_old = true;
    
    //TODO: start printing commands?
}

void PointCloudProcessing::send_mvp_matrix(){
    Matrix4x4 mvp = Matrix4x4(camera_matrix.data) * Matrix4x4(projection_matrix.data);
    glUniformMatrix4fv(mvp_uniform, 1, GL_FALSE, (float *)mvp);
}

bool PointCloudProcessing::aligning(){
    return aligning_to_old;
}

void PointCloudProcessing::render_point_cloud(){
    //clear the color buffer bit before every time
    //TODO: do we need to clear the depth buffer every bit as well?
    glClearColor(0, 0, 0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    pointcloud_state state = pointcloud_get_state();
//    std::cout<<"Rendering point cloud state = "<<state<<std::endl;
    if (state == POINTCLOUD_INITIALIZING || state == POINTCLOUD_TRACKING_SLAM_MAP) {
//    if (state == POINTCLOUD_INITIALIZING) {
//        std::cout<<"initializing or tracking slam map"<<std::endl;
        
        pointcloud_point_cloud* points = pointcloud_get_points();
        
        //if points is valid, display them
        if (points) {
            glEnable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_SRC_ALPHA);
            
            //model view projection matrix
//            Matrix4x4 mvp = Matrix4x4(camera_matrix.data) * Matrix4x4(projection_matrix.data);
//            std::cout<<"mvp"<<std::endl;
//            mvp.print();

//            GLuint mvp_uniform = glGetUniformLocation(program, "modelViewProjectionMatrix");
//            GLuint color_uniform = glGetUniformLocation(program, "pointcolor");
//            glUniformMatrix4fv(mvp_uniform, 1, GL_FALSE, (float *)mvp);
            send_mvp_matrix();
            if (state == POINTCLOUD_INITIALIZING){
                glUniform4f(color_uniform, 1.0, 1.0, 0, 1.0);
            }
            else{
                glUniform4f(color_uniform, 1.0, 0, 0, 1.0);
            }
            
            //TODO: add points to the buffer (_vertexBuffer in the graphicsSingleton...)?
            glBufferData(GL_ARRAY_BUFFER, 3*sizeof(float)*5012, NULL, GL_DYNAMIC_DRAW);
            glBufferData(GL_ARRAY_BUFFER, 3*sizeof(float)*(std::min(5012, (int)points->size)), (float *)points->points, GL_DYNAMIC_DRAW);
            glEnableVertexAttribArray(ATTRIB_POINTPOS);
            glVertexAttribPointer(ATTRIB_POINTPOS, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
            glDrawArrays(GL_POINTS, 0, points->size);
            
			pointcloud_destroy_point_cloud(points);
        }
        
//        glDisableVertexAttribArray(ATTRIB_POINTPOS);
//    } else if (state == POINTCLOUD_TRACKING_IMAGES) {
//        printf("tracking images\n");
    }
//    } else if (state == POINTCLOUD_TRACKING_SLAM_MAP){
////        std::cout<<"tracking slam map"<<std::endl;
//        //here it is tracking the camera pose
//        camera_pose = pointcloud_get_camera_pose();
////        Matrix4x4 cp = Matrix4x4(camera_pose.data);
////        cp.print();
//    }
}

float PointCloudProcessing::arrows(){
    if (aligning_to_old){
        // compute arrow transformation
        glClearColor(0, 0, 0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        //difference between object location
        //        Vector3D current_object_loc = current_camera_pose.getObjectLocation();
        //        std::cout<<"current object loc"<<std::endl;
        //        current_object_loc.print();
        
        //translation to desired camera location
        Vector3D translation_to_desired = desired_camera_pose.translationToDesiredPose(current_camera_pose);
        
        //        std::cout<<"current camera pose"<<std::endl;
        //        current_camera_pose.print();
    
    
        std::cout<<"translation to desired pose"<<std::endl;
        translation_to_desired.print();
        
        //set identity MVP
        Matrix4x4 mvp = Matrix4x4();
        glUniformMatrix4fv(mvp_uniform, 1, GL_FALSE, (float *)mvp);
        //TODO: multiply mvp by the orthographic matrix that is the viewport (from -1 to 1)?
        
        //change color to indicate whether to move forwards or backwards
        //positive z means move forward (more green)
        //negative z means move backward (more red)
        float z_color = fmin(1.0, fabs(translation_to_desired.z)/0.08);
        std::cout<<"z_color = "<<z_color<<std::endl;
        if (translation_to_desired.z > 0)
            glUniform4f(color_uniform, z_color, 1.0-z_color, 0, 1.0);
        else
            glUniform4f(color_uniform, 1.0-z_color, z_color, 0, 1.0);

//        if (translation_to_desired.z > 0)
//            glUniform4f(color_uniform, 1.0, 0, 0, 1.0);
//        else
//            glUniform4f(color_uniform, 0, 1.0, 0, 1.0);
        
        const GLfloat line[] =
        {
            0.0f, 0.0f, //"origin"
            translation_to_desired.y, translation_to_desired.x, //"desired"
        };
    
        glBufferData(GL_ARRAY_BUFFER, 2*sizeof(float)*sizeof(line)/(2.0*sizeof(GLfloat)), NULL, GL_DYNAMIC_DRAW);
        glBufferData(GL_ARRAY_BUFFER, sizeof(line), (float *)line, GL_DYNAMIC_DRAW);
        glLineWidth(4.0);
    
        glEnableVertexAttribArray(ATTRIB_POINTPOS);
        glVertexAttribPointer(ATTRIB_POINTPOS, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), 0);
        //rendering 2 points
        glDrawArrays(GL_LINES, 0, sizeof(line)/(2.0*sizeof(GLfloat)));
        
        return translation_to_desired.length();
//        return translation_to_desired.xy_length();
    }
    return -1;
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
    
    pointcloud_matrix_4x4 ccp = pointcloud_get_camera_pose();
//    Matrix4x4 current_camera_pose_mat = Matrix4x4(ccp.data);
//    Pose current_camera_pose = Pose(current_camera_pose_mat);
    current_camera_pose = Pose(ccp.data);
    
//    std::cout<<"current camera pose"<<std::endl;
//    current_camera_pose.print();
}