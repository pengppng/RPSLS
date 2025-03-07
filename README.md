# code ที่ป้องกันการ lock เงินไว้ใน contract


# code ซ่อน choice และ commit
randomString เพื่อป้องกัน front-running และ ใช้ keccak256(abi.encodePacked(choice, randomString)) เพื่อซ่อนตัวเลือก

# code จัดการกับความล่าช้าที่ผู้เล่นไม่ครบทั้งสองคนเสียที
if case มีแค่คนเดียวที่ commit แล้วอีกคนไม่มาเล่น หรือ ไม่มีอีกคนจริง -> ระบบต้องคืนเงิน

# code reveal และนำ choice มาตัดสินผู้ชนะ
คนเล่นต้องส่งค่า commitHash = keccak256(abi.encodePacked(choice, randomString)) ตอน addPlayer() เพื่อยืนยันว่าถูก add แล้ว เปิดเผยค่าโดยส่ง choice
