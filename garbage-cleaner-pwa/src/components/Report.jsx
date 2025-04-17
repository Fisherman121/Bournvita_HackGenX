import React from 'react';
import { Box, Typography, Paper, Grid, CircularProgress } from '@mui/material';
import { CheckCircle, Warning, Error } from '@mui/icons-material';

const Report = ({ tasks }) => {
  const totalTasks = tasks.length;
  const completedTasks = tasks.filter(task => task.completed).length;
  const pendingTasks = totalTasks - completedTasks;
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  return (
    <Box sx={{ mt: 4 }}>
      <Typography variant="h6" gutterBottom>
        Cleaning Report
      </Typography>
      <Grid container spacing={2}>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h4">{totalTasks}</Typography>
            <Typography variant="subtitle1">Total Tasks</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h4" color="success.main">
              {completedTasks}
            </Typography>
            <Typography variant="subtitle1">Completed</Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} md={4}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h4" color="warning.main">
              {pendingTasks}
            </Typography>
            <Typography variant="subtitle1">Pending</Typography>
          </Paper>
        </Grid>
      </Grid>

      <Paper sx={{ p: 2, mt: 2, textAlign: 'center' }}>
        <Box sx={{ position: 'relative', display: 'inline-flex' }}>
          <CircularProgress
            variant="determinate"
            value={completionRate}
            size={100}
            thickness={4}
          />
          <Box
            sx={{
              top: 0,
              left: 0,
              bottom: 0,
              right: 0,
              position: 'absolute',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            <Typography variant="h6" component="div" color="text.secondary">
              {`${Math.round(completionRate)}%`}
            </Typography>
          </Box>
        </Box>
        <Typography variant="subtitle1" sx={{ mt: 2 }}>
          Completion Rate
        </Typography>
      </Paper>

      <Paper sx={{ p: 2, mt: 2 }}>
        <Typography variant="h6" gutterBottom>
          Recent Activity
        </Typography>
        {tasks.slice(0, 5).map((task) => (
          <Box
            key={task.id}
            sx={{
              display: 'flex',
              alignItems: 'center',
              mb: 1,
              p: 1,
              bgcolor: task.completed ? 'success.light' : 'warning.light',
              borderRadius: 1,
            }}
          >
            {task.completed ? (
              <CheckCircle color="success" sx={{ mr: 1 }} />
            ) : (
              <Warning color="warning" sx={{ mr: 1 }} />
            )}
            <Typography variant="body2">
              {task.location} - {new Date(task.timestamp).toLocaleString()}
            </Typography>
          </Box>
        ))}
      </Paper>
    </Box>
  );
};

export default Report; 