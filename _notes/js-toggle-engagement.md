// Upvote
async function toggleUpvote(announcementId) {
  try {
    const response = await fetch(`/announcements/${announcementId}/upvote`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    if (data.status === 'added') {
      // Update UI : count +1, button highlighted
      console.log('Upvoted!');
    } else if (data.status === 'removed') {
      // Update UI : count -1, button normal
      console.log('Upvote removed!');
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

// Interested
async function toggleInterested(announcementId) {
  try {
    const response = await fetch(`/announcements/${announcementId}/interested`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    if (data.status === 'added') {
      // Update UI : count +1, button highlighted
      console.log('Interested!');
    } else if (data.status === 'removed') {
      // Update UI : count -1, button normal
      console.log('Interest removed!');
    }
  } catch (error) {
    console.error('Error:', error);
  }
}

// Dans le HTML :
// <button onclick="toggleUpvote(123)">⬆️ 180</button>
// <button onclick="toggleInterested(123)">👋 12</button>