#include <cmath>
#include <sead/math/seadVector.h>

constexpr float fovy = 45.0f;

float getFovyHook()
{
    return fovy;
}

// should be in a seperate header and proper namespace never do this please
struct PerspectiveProjection {
    u8 _0[0x9C];
    float fovy;
    sead::Vector3f fovyVec;
};

void setFovy_Hook(PerspectiveProjection& dis, float x)
{
    dis.fovy = fovy;
    dis.fovyVec = { std::sin(fovy), std::cos(fovy), std::tan(fovy) };
    dis._0[4] = 1;
}