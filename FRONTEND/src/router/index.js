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
    path: '/create-quick',
    name: 'CreateQuickRoom',
    component: () => import('../views/CreateQuickRoom.vue')
  },
  {
    path: '/room/:roomId',
    name: 'GroupRoom',
    component: () => import('../views/GroupRoom.vue')
  },
  {
    path: '/group/:roomId',
    name: 'GroupRoom',
    component: () => import('../views/GroupRoom.vue')
  },
  {
    path: '/quick/:roomId',
    name: 'QuickRoom',
    component: () => import('../views/QuickRoom.vue') // Por ahora usa el mismo Room.vue
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router