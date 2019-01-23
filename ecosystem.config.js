module.exports = {
  apps : [{
    name: 'jonathanlee.io',
    cwd: '/var/nodes/jonathanlee.io',
    autorestart: true,
    watch: true,
    exec_mode: 'cluster',
    script: 'npm',
    args: 'start'
    }]
};
