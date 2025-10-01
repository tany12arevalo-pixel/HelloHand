import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/menu-grupal',
    name: 'MenuGrupal',
    component: () => import('../views/MenuGrupal.vue')
  },
  {
    path: '/room/:roomId',
    name: 'Room',
    component: () => import('../views/Room.vue')
  },
  {
    path: '/group/:roomId',
    name: 'GroupRoom',
    component: () => import('../views/Room.vue') // Por ahora usa el mismo Room.vue
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router