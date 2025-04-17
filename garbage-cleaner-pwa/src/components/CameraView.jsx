import React, { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';

const CameraView = () => {
  const [selectedZone, setSelectedZone] = useState('1');

  const handleZoneChange = (event) => {
    setSelectedZone(event.target.value);
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold">Camera Feed</h2>
      
      <div className="grid grid-cols-1 gap-6">
        <div>
          <FormControl fullWidth>
            <InputLabel>Select Zone</InputLabel>
            <Select
              value={selectedZone}
              label="Select Zone"
              onChange={handleZoneChange}
            >
              <MenuItem value="1">Zone 1</MenuItem>
              <MenuItem value="2">Zone 2</MenuItem>
              <MenuItem value="3">Zone 3</MenuItem>
            </Select>
          </FormControl>
        </div>

        <div>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Zone {selectedZone} Camera Feed
            </Typography>
            <Box
              sx={{
                width: '100%',
                height: '400px',
                backgroundColor: 'grey.200',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}
            >
              <Typography variant="body1" color="text.secondary">
                Camera feed will be displayed here
              </Typography>
            </Box>
          </Paper>
        </div>
      </div>
    </div>
  );
};

export default CameraView; 