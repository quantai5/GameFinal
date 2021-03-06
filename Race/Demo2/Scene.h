#ifndef __SCENE_CLASS_H__
#define __SCENE_CLASS_H__

using namespace gf;

class Scene
{
public:
	Scene(IDevice* device, IVideoDriver* driver);
	
	virtual void Enter() = 0;
	virtual void Update(float dt) = 0;
	virtual void Render() = 0;
	virtual void Exit() = 0;

	virtual ~Scene();
protected:
	ISceneManager*		mSceneManager;
	IDevice*			mDevice;
	IVideoDriver*		mVideoDriver;

};

#endif
