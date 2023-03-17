extends Node3D

#it seems to be hard to get it to work with different bone sets, probably due to different vertex weights
#sometimes it is disconnected, possibly due to choice of bones or due to mnesh being cut up and the skin not stretching
#try rigging godette through mixamo, if it works okay with mixamo thats good enough, anyone else can add to it if they need to
#it still shows how to do it, it should work if you have a rigidBody for every nonIK bone

#model and rigidBodies must start in the same pose, so I make it as a T-Pose

#to do:
#show the self balancing aspect of the ragdoll:
#   make a scene with no centre of mass, and with no grav scale
#    to show the balance and uprightness, using the mixamo model
#   this gives people the basis
#    show how to change it for different bone names
#    show limitations with expecting it to work perfectly with all models



#things we change in ready
var skeleton = null #needs to be assigned before this ready funbction is called
var rigidBodiesFromBones = {}
var rigidBodyParent = self #if not self we need to tell , 

#dictionaries that are just for the code to use to optimise process
var rigidBodiesInitialTForms = {}
var rigidBodiesInverseTForms = {}
var boneInitialTForms = {}
var boneNameToIndex = {}




# Called when the node enters the scene tree for the first time.
func _ready():
	#this has to be set for your model
	skeleton = $godetteMixamo/Armature/Skeleton3D
	#so does this
	rigidBodiesFromBones = {
		#"BONE_NAME" : "RIGIDBODY_NODE_NAME",
		#we put the name of our bone as the key
		#we put the name of the corresponding rigidBody as the value (has to be child of skeleton)
		#so if we change the model but keep the ragdoll, then we only change the keys
		#the rest of the data will be generated from this list and the data in skeleton
		"mixamorig_Hips" : "Hips",
		"mixamorig_Spine1" : "Spine1",
		"mixamorig_Spine2" : "Spine2",
		"mixamorig_Head" : "Head",
		"mixamorig_LeftArm" : "LeftArm",
		"mixamorig_LeftForeArm" : "LeftForeArm",
		"mixamorig_LeftHand" : "LeftHand",
		"mixamorig_RightArm" : "RightArm",
		"mixamorig_RightForeArm" : "RightForeArm",
		"mixamorig_RightHand" : "RightHand",
		"mixamorig_LeftUpLeg" : "LeftUpLeg",
		"mixamorig_RightUpLeg" : "RightUpLeg",
		"mixamorig_LeftLeg" : "LeftLeg",
		"mixamorig_RightLeg" : "RightLeg",
	}
	
	
	
	
	
	
	#rigidBodyParent must have the same transform as skeleton, we can make them the same to enforce this
	#rigidBodyParent = skeleton
	#or have a different rigidBodyParent,e.g. to make it easier to demonstrate changing meshes
	rigidBodyParent = $rigidBodyParent
	
	
	#has to be done after skeleton is set and rigidBodiesFromBones
	get_initial_tforms() #we calculate all constant values so we can minimise what we need to calculate each frame


func get_initial_tforms():
	#we save a bunch of original transforms to convert transforms later, may seem overkill but...
	#the original method required joints or rigidBodies to have a original transform that was the same as the bones transform
	#this made creating ragdolls very annoying, now it works with any original rigidBody transform
	
	for boneName in rigidBodiesFromBones.keys():
		#get bone index (searching for it takes a long time):
		boneNameToIndex[boneName] = skeleton.find_bone(boneName)
		
		var rigidBodyName = rigidBodiesFromBones[boneName]
		var tForm = rigidBodyParent.get_node(rigidBodyName).transform
		rigidBodiesInitialTForms[rigidBodyName] = tForm
		#calculate the inverse of the original transform as this, at least theoreticallly, takes a long time
		rigidBodiesInverseTForms[rigidBodyName] = tForm.affine_inverse() ##this tForm should have no scaling if we want normal inverse()
		
		var boneIndex = boneNameToIndex[boneName]#skeleton_bones_sync[boneName]
		boneInitialTForms[boneName] = skeleton.get_bone_global_pose(boneIndex) #returns transform relative to skeleton








func _process(delta):
	deform_skeleton_with_rigidBodies() #move mesh bones to match rigidBody skeleton


#############################
#   Most important part
#############################
#This is the function that handles deforming the skeleton which defprms the mesh to align with the reigidBody ragdoll jointed structure
func deform_skeleton_with_rigidBodies():
	#this should do it for a general ragdoll, as long as we give it the bones to use
	#this could be made faster if made specific but I wanted to write it so the 
	#code could work with other models as long as the bones start in the same pose as the rigidBodies
	for boneName in rigidBodiesFromBones.keys():
		var boneIndex = boneNameToIndex[boneName] #get bone Index
		#get rigidBody
		var rB_name = rigidBodiesFromBones[boneName]
		var rigid_body_match = rigidBodyParent.get_node(rB_name) #rigidBodyParent.get_node(rB_name)
		if rigid_body_match == null:
			continue
		#now we have the rigidBody, get its transform
		var rB_tForm_final = rigid_body_match.transform
		#get our desired transform
		#this is the transform required to move the rigidBody from its initial state to its current state
		var relative_tForm = rB_tForm_final*rigidBodiesInverseTForms[rB_name] #what is the rotation and translation required to move the rigidBody from its initial state
		#apply this transform to the initial bone transform, if they started in the same pose then this should move it to the right spot
		var final_bone_tForm = relative_tForm*boneInitialTForms[boneName]
		
		#actually apply the transform to the bone
		skeleton.set_bone_global_pose_override(boneIndex, final_bone_tForm, 1, true)



