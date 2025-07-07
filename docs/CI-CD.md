# 🔄 CI/CD Pipeline Documentation

## Node.js Version Testing Strategy

### Why Test Multiple Node.js Versions?

We test on **Node.js 18.x and 20.x** to ensure:

- ✅ **Compatibility**: App works on both LTS versions
- ✅ **Future-proofing**: Ready for Node.js 20.x adoption
- ✅ **Dependency compatibility**: All packages work on both versions
- ✅ **Template reliability**: Users can use either version

### Version Strategy:
- **Node.js 18.x**: Current LTS (Long Term Support)
- **Node.js 20.x**: Latest LTS (recommended for new projects)

### Visual Tests in CI

**How Playwright works in CI:**
- ✅ **Headless browsers**: No GUI needed
- ✅ **Virtual displays**: Simulated screen interactions
- ✅ **Screenshot capture**: Can take images for comparison
- ✅ **Element interaction**: Click, type, scroll just like real users

**What we test:**
- Component presence and structure
- Responsive design across viewports
- Data loading and display
- UI element accessibility

**No screenshots in CI because:**
- Font rendering differs between environments
- Pixel-perfect comparison is brittle
- Component structure testing is more reliable
