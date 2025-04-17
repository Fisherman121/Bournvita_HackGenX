import React from 'react';
import {
  Paper,
  Typography,
  CardContent,
  LinearProgress,
  IconButton
} from '@mui/material';
import {
  Assignment as AssignmentIcon,
  CheckCircle as CheckCircleIcon,
  Warning as WarningIcon,
  AccessTime as AccessTimeIcon
} from '@mui/icons-material';

const StatCard = ({ title, value, icon, color }) => (
  <div className="bg-white rounded-lg shadow-md h-full">
    <CardContent>
      <div className="flex items-center mb-2">
        <IconButton sx={{ color: color, mr: 1 }}>
          {icon}
        </IconButton>
        <Typography variant="h6" component="div">
          {title}
        </Typography>
      </div>
      <Typography variant="h4" component="div" sx={{ mb: 1 }}>
        {value}
      </Typography>
    </CardContent>
  </div>
);

const Dashboard = ({ tasks }) => {
  const totalTasks = tasks?.length || 0;
  const completedTasks = tasks?.filter(task => task.status === 'cleaned').length || 0;
  const pendingTasks = totalTasks - completedTasks;
  const completionRate = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0;

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold mb-6">
        Dashboard Overview
      </h2>
      
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <StatCard
          title="Total Tasks"
          value={totalTasks}
          icon={<AssignmentIcon />}
          color="primary"
        />
        <StatCard
          title="Completed"
          value={completedTasks}
          icon={<CheckCircleIcon />}
          color="success"
        />
        <StatCard
          title="Pending"
          value={pendingTasks}
          icon={<WarningIcon />}
          color="warning"
        />
        <StatCard
          title="Completion Rate"
          value={`${completionRate.toFixed(1)}%`}
          icon={<AccessTimeIcon />}
          color="info"
        />
      </div>

      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" sx={{ mb: 2 }}>
          Task Completion Progress
        </Typography>
        <div className="flex items-center mb-1">
          <div className="flex-grow mr-1">
            <LinearProgress 
              variant="determinate" 
              value={completionRate} 
              color={completionRate > 80 ? "success" : "primary"}
            />
          </div>
          <Typography variant="body2" color="text.secondary">
            {completionRate.toFixed(1)}%
          </Typography>
        </div>
        <Typography variant="body2" color="text.secondary">
          {completedTasks} of {totalTasks} tasks completed
        </Typography>
      </Paper>
    </div>
  );
};

export default Dashboard; 