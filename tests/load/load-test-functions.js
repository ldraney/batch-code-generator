module.exports = {
  $randomString: function() {
    const types = ['component', 'function', 'class', 'interface', 'type'];
    return types[Math.floor(Math.random() * types.length)];
  },
  
  $timestamp: function() {
    return new Date().toISOString();
  }
};
