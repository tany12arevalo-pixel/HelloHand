import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/room/:roomId',
    name: 'Room',
    component: () => import('../views/Room.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router