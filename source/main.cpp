#include <stdlib.h>

namespace al {
class ByamlIter {
};
bool tryGetByamlU8ByIndex(unsigned char*, const al::ByamlIter&, int);
}

void testHook(unsigned char* out, const al::ByamlIter& iter, int index)
{
    al::tryGetByamlU8ByIndex(out, iter, index);
}