import core.runtime, core.time : MonoTime;
import core.stdc.stdio;

ModuleInfo* getModuleInfo(string name)
{
    foreach (m; ModuleInfo)
        if (m.name == name) return m;
    assert(0, "module '"~name~"' not found");
}

UnitTestResult tester()
{
    return Runtime.args.length > 1 ? testModules() : testAll();
}

string mode;


UnitTestResult testModules()
{
    UnitTestResult ret;
    ret.summarize = false;
    ret.runMain = false;
    foreach (name; Runtime.args[1..$])
    {
        immutable pkg = ".package";
        immutable pkgLen = pkg.length;

        if (name.length > pkgLen && name[$ - pkgLen .. $] == pkg)
            name = name[0 .. $ - pkgLen];

        doTest(getModuleInfo(name), ret);
    }

    return ret;
}

UnitTestResult testAll()
{
    UnitTestResult ret;
    ret.summarize = false;
    ret.runMain = false;
    foreach (moduleInfo; ModuleInfo)
    {
        doTest(moduleInfo, ret);
    }

    return ret;
}


void doTest(ModuleInfo* moduleInfo, ref UnitTestResult ret)
{
    if (auto fp = moduleInfo.unitTest)
    {
        auto name = moduleInfo.name;
        ++ret.executed;
        try
        {
            immutable t0 = MonoTime.currTime;
            fp();
            ++ret.passed;
            printf("%.3fs PASS %.*s %.*s\n",
                   (MonoTime.currTime - t0).total!"msecs" / 1000.0,
                   cast(uint)mode.length, mode.ptr,
                   cast(uint)name.length, name.ptr);
        }
        catch (Throwable e)
        {
            auto msg = e.toString();
            printf("****** FAIL %.*s %.*s\n%.*s\n",
                   cast(uint)mode.length, mode.ptr,
                   cast(uint)name.length, name.ptr,
                   cast(uint)msg.length, msg.ptr);
        }
    }
}


shared static this()
{
    version(D_Coverage)
    {
        import core.runtime : dmd_coverSetMerge;
        dmd_coverSetMerge(true);
    }
    Runtime.extendedModuleUnitTester = &tester;

    debug mode = "debug";
    else  mode =  "release";
    static if ((void*).sizeof == 4) mode ~= "32";
    else static if ((void*).sizeof == 8) mode ~= "64";
    else static assert(0, "You must be from the future!");
}

void main()
{
}
