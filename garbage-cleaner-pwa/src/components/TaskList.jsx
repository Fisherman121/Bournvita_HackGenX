import React from 'react';
import {
  List,
  ListItem,
  ListItemText,
  Checkbox,
  Typography,
  Box,
  Chip,
  Avatar,
  IconButton,
  Tooltip,
  useTheme
} from '@mui/material';
import {
  Delete as DeleteIcon,
  AccessTime as AccessTimeIcon,
  LocationOn as LocationIcon,
  Image as ImageIcon
} from '@mui/icons-material';
import { styled } from '@mui/material/styles';

const StyledListItem = styled(ListItem)(({ theme }) => ({
  backgroundColor: theme.palette.background.paper,
  marginBottom: theme.spacing(1),
  borderRadius: theme.shape.borderRadius,
  '&:hover': {
    backgroundColor: theme.palette.action.hover,
  },
}));

const TaskImage = styled('img')(({ theme }) => ({
  width: 100,
  height: 100,
  objectFit: 'cover',
  borderRadius: theme.shape.borderRadius,
  marginLeft: theme.spacing(2),
}));

// Flask server configuration
const FLASK_SERVER = 'http://localhost:8080';

const TaskList = ({ tasks, onTaskComplete }) => {
  const theme = useTheme();

  if (!tasks || tasks.length === 0) {
    return (
      <Box sx={{ 
        display: 'flex', 
        flexDirection: 'column', 
        alignItems: 'center', 
        justifyContent: 'center',
        p: 3,
        textAlign: 'center'
      }}>
        <ImageIcon sx={{ fontSize: 48, color: 'text.secondary', mb: 2 }} />
        <Typography variant="h6" color="text.secondary">
          No tasks in this zone
        </Typography>
        <Typography variant="body2" color="text.secondary">
          New detections will appear here automatically
        </Typography>
      </Box>
    );
  }

  return (
    <List>
      {tasks.map((task) => (
        <StyledListItem
          key={task.timestamp}
          secondaryAction={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Tooltip title={task.status === 'cleaned' ? 'Mark as pending' : 'Mark as cleaned'}>
                <Checkbox
                  edge="end"
                  checked={task.status === 'cleaned'}
                  onChange={() => onTaskComplete(task.timestamp, task.status === 'cleaned' ? 'pending' : 'cleaned')}
                />
              </Tooltip>
            </Box>
          }
        >
          <ListItemText
            primary={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                <Typography variant="subtitle1" sx={{ fontWeight: 'bold' }}>
                  {task.class}
                </Typography>
                <Chip
                  size="small"
                  label={`${(task.confidence * 100).toFixed(0)}% confidence`}
                  color={task.confidence > 0.8 ? 'success' : 'warning'}
                />
              </Box>
            }
            secondary={
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <AccessTimeIcon fontSize="small" color="action" />
                  <Typography variant="body2" color="text.secondary">
                    {new Date(task.timestamp).toLocaleString()}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <LocationIcon fontSize="small" color="action" />
                  <Typography variant="body2" color="text.secondary">
                    {task.location || 'Unknown Location'}
                  </Typography>
                </Box>
              </Box>
            }
          />
          {task.image_path && (
            <TaskImage
              src={`${FLASK_SERVER}/view_image/${task.image_path}`}
              alt="Garbage location"
              onError={(e) => {
                console.error('Error loading image:', e.target.src);
                e.target.style.display = 'none';
              }}
            />
          )}
        </StyledListItem>
      ))}
    </List>
  );
};

export default TaskList; 