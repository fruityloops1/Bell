#include <nn/fs.h>

namespace al {
class ByamlIter;
bool tryGetByamlU8ByIndex(unsigned char* out, const ByamlIter& iter, int index);
}

void testHook(unsigned char* out, const al::ByamlIter& iter, int index)
{
    al::tryGetByamlU8ByIndex(out, iter, index);
    int* d = new int;
    delete d;
}