import React, { useState, useEffect } from 'react';
import { 
  Container, 
  Box, 
  Typography, 
  Paper, 
  AppBar, 
  Toolbar, 
  Drawer, 
  List, 
  ListItem, 
  ListItemIcon, 
  ListItemText, 
  Avatar, 
  IconButton,
  Badge,
  Divider,
  useTheme,
  useMediaQuery,
  Button
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard as DashboardIcon,
  Assignment as AssignmentIcon,
  Settings as SettingsIcon,
  Notifications as NotificationsIcon,
  Person as PersonIcon,
  Camera as CameraIcon,
  LocationOn as LocationIcon
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';
import { BrowserRouter as Router, Routes, Route, Link, useLocation } from 'react-router-dom';
import TaskList from './components/TaskList';
import Dashboard from './components/Dashboard';
import CameraView from './components/CameraView';

// Flask server configuration
const FLASK_SERVER = 'http://localhost:8080';

// Styled components
const StyledDrawer = styled(Drawer)(({ theme }) => ({
  '& .MuiDrawer-paper': {
    backgroundColor: theme.palette.primary.main,
    color: theme.palette.primary.contrastText,
    width: 240,
  },
}));

const StyledListItem = styled(ListItem)(({ theme }) => ({
  '&:hover': {
    backgroundColor: theme.palette.primary.light,
  },
  '&.Mui-selected': {
    backgroundColor: theme.palette.primary.dark,
  },
}));

const StyledLink = styled(Link)(({ theme }) => ({
  textDecoration: 'none',
  color: 'inherit',
  width: '100%',
}));

function AppContent() {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [tasks, setTasks] = useState([]);
  const [error, setError] = useState(null);
  const [selectedZone, setSelectedZone] = useState('Zone 1');
  const [user, setUser] = useState({
    name: 'John Doe',
    role: 'Cleaner',
    zones: ['Zone 1', 'Zone 2', 'Zone 3'],
    avatar: 'JD'
  });

  useEffect(() => {
    fetchTasks();
    const interval = setInterval(fetchTasks, 5000);
    return () => clearInterval(interval);
  }, [selectedZone]);

  const fetchTasks = async () => {
    try {
      const response = await fetch(`${FLASK_SERVER}/get_logs`);
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      
      const data = await response.json();
      const zoneTasks = data.filter(task => 
        task.forCleaning && 
        task.zone_name === selectedZone
      );
      
      setTasks(zoneTasks);
      setError(null);
    } catch (error) {
      console.error('Error fetching tasks:', error);
      setError(error.message);
    }
  };

  const handleTaskComplete = async (timestamp, newStatus) => {
    try {
      const response = await fetch(`${FLASK_SERVER}/update_status`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ timestamp, status: newStatus }),
      });
      
      if (response.ok) {
        setTasks(tasks.map(task => 
          task.timestamp === timestamp 
            ? { ...task, status: newStatus }
            : task
        ));
      }
    } catch (error) {
      console.error('Error updating task status:', error);
    }
  };

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const drawer = (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <Box sx={{ p: 2, display: 'flex', alignItems: 'center', gap: 2 }}>
        <Avatar sx={{ bgcolor: 'secondary.main' }}>{user.avatar}</Avatar>
        <Box>
          <Typography variant="subtitle1">{user.name}</Typography>
          <Typography variant="body2" color="text.secondary">{user.role}</Typography>
        </Box>
      </Box>
      <Divider sx={{ bgcolor: 'primary.light' }} />
      <List>
        <StyledLink to="/">
          <StyledListItem selected={location.pathname === '/'}>
            <ListItemIcon>
              <DashboardIcon sx={{ color: 'primary.contrastText' }} />
            </ListItemIcon>
            <ListItemText primary="Dashboard" />
          </StyledListItem>
        </StyledLink>
        <StyledLink to="/tasks">
          <StyledListItem selected={location.pathname === '/tasks'}>
            <ListItemIcon>
              <AssignmentIcon sx={{ color: 'primary.contrastText' }} />
            </ListItemIcon>
            <ListItemText primary="Tasks" />
          </StyledListItem>
        </StyledLink>
        <StyledLink to="/camera">
          <StyledListItem selected={location.pathname === '/camera'}>
            <ListItemIcon>
              <CameraIcon sx={{ color: 'primary.contrastText' }} />
            </ListItemIcon>
            <ListItemText primary="Camera" />
          </StyledListItem>
        </StyledLink>
      </List>
      <Divider sx={{ bgcolor: 'primary.light' }} />
      <Typography variant="subtitle2" sx={{ p: 2, color: 'primary.contrastText' }}>
        Zones
      </Typography>
      <List>
        {user.zones.map((zone) => (
          <StyledListItem 
            key={zone}
            selected={selectedZone === zone}
            onClick={() => setSelectedZone(zone)}
          >
            <ListItemIcon>
              <LocationIcon sx={{ color: 'primary.contrastText' }} />
            </ListItemIcon>
            <ListItemText primary={zone} />
          </StyledListItem>
        ))}
      </List>
    </Box>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar position="fixed" sx={{ zIndex: theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <IconButton
            color="inherit"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            Garbage Cleaner Portal
          </Typography>
          <IconButton color="inherit">
            <Badge badgeContent={4} color="error">
              <NotificationsIcon />
            </Badge>
          </IconButton>
          <IconButton color="inherit">
            <SettingsIcon />
          </IconButton>
        </Toolbar>
      </AppBar>

      <StyledDrawer
        variant={isMobile ? 'temporary' : 'permanent'}
        open={isMobile ? mobileOpen : true}
        onClose={handleDrawerToggle}
      >
        {drawer}
      </StyledDrawer>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          p: 3,
          width: { sm: `calc(100% - 240px)` },
          mt: '64px'
        }}
      >
        <Routes>
          <Route path="/" element={<Dashboard tasks={tasks} />} />
          <Route 
            path="/tasks" 
            element={
              <Paper sx={{ p: 3, mb: 3 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="h5">
                    {selectedZone} Tasks
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {tasks.length} pending tasks
                  </Typography>
                </Box>
                {error && (
                  <Typography color="error" sx={{ mb: 2 }}>
                    Error: {error}
                  </Typography>
                )}
                <TaskList 
                  tasks={tasks} 
                  onTaskComplete={handleTaskComplete}
                />
              </Paper>
            } 
          />
          <Route path="/camera" element={<CameraView />} />
        </Routes>
      </Box>
    </Box>
  );
}

function App() {
  return (
    <Router>
      <AppContent />
    </Router>
  );
}

export default App;
