<template>
  <v-container fluid class="main-container">
    <!--
      Context menu component when clicking treeview items
      components/index-page/context-menu.vue
    -->
    <ContextMenu />

    <!--
     Dialog for drupal edit page via iframe - currently not in use - accesses by contextmenu - edit
      components/index-page/edit-dialog.vue
    -->
    <EditDialog />

    <Splitpanes id="vuer-panels">
      <Pane size="15" min-size="15" style="overflow-y: auto;">
        <!--
          toolbar in left pane that houses treeview actions
          components/index-page/treeview-pane-toolbar.vue
        -->
        <TreeviewPaneToolbar />

        <v-progress-linear
          :active="loading"
          indeterminate
        />

        <!--
          Main reusable treeview compoent used to display drupal tree
          components/treeview.vue
        -->
        <Treeview
          :active.sync="active"
          :items="items"
          :load-children="loadChildren"
          :open.sync="open"
          v-bind="{ openMenu, treeViewLabelClick }"
        />
      </Pane>
      <Pane>
        <Splitpanes horizontal>
          <Pane :size="chipPaneSize" style="overflow-y: auto">
            <!--
              Top right panel that hides/shows when an outline/entry has children
              components/index-page/chip-pane.vue
            -->
            <ChipPane  />
          </Pane>
          <Pane>
            <!--
              Bottom right panel thats used to show rendered content of selected outline/entry
              components/index-page/content-pane.vue
            -->
            <ContentPane />
          </Pane>
        </Splitpanes>
      </Pane>
    </Splitpanes>
  </v-container>
</template>

<script>
// utilities
import { computed, reactive, watch } from '@nuxtjs/composition-api'
import { difference, find } from 'lodash'
import pathify from '@/utils/pathify'

// components
import { Pane, Splitpanes } from 'splitpanes'
import 'splitpanes/dist/splitpanes.css'

export default {
  name: 'IndexPage',

  components: {
    Pane,
    Splitpanes,
  },

  setup (props, context) {
    const { call, get, sync } = pathify(context)

    // drawer getters
    const selectedOutlines = get('bookmarks/outlines')
    const isBookmark = get('bookmarks/active')
    const open = sync('graphql/opened')

    // loading getters
    const isFetchingEntries = get('graphql/isFetchingEntries')
    const isFetchingOutlines = get('graphql/isFetchingOutlines')
    const loading = computed(() => {
      return isFetchingOutlines.value || isFetchingEntries.value
    })

    // treeview props
    const active = sync('treeview/active')
    const activeItem = get('treeview/activeItem')

    // outline getters
    const toutlines = get('graphql/outlines')
    const aOutlines = get('graphql/activeOutlines')
    const entries = get('graphql/entries')

    // actions
    const openMenu = (e, item) => {
      return call('context-menu/openMenu', { e, item })
    }

    // init outline fetch
    const items = computed(() => {
      const bookmark = !!isBookmark?.value || 0
      const outlines = bookmark
        ? selectedOutlines?.value || []
        : aOutlines?.value || []

      return toutlines.value.filter(item => outlines.includes(item.eid))
    })

    // hides and shows chip-pane
    const chipPaneSize = computed(() => {
      return activeItem?.value?.children?.length ? 20 : 0
    })

    // sets active item when treeview label is clicked
    const treeViewLabelClick = async (item) => {
      await call('treeview/setActiveItem', item)
    }

    // function for loading children when a treeview node is clicked
    const loadChildren = async (entry) => {
      const { eid, server } = entry
      console.log('loading children for:', eid, 'server', server)
      const { children } = await call('graphql/fetchEntry', { eid, server })
      children.forEach((child) => {
        child.server = server
      })
      entry.children = children
      return children
    }

    // expand collapse logic when a treeview node is open/closed
    watch(open, (val, prevVal) => {
      // may need to add debounce
      const expandItems = difference(val, prevVal)
      const collapseItems = difference(prevVal, val)
      console.log('diff', expandItems, collapseItems)
      if (expandItems.length) {
        for (const item of expandItems) {
          const entry = find(entries.value, { eid: item })
          if (entry) {
            console.log('open', entry)
            call('graphql/expandEntry', entry)
          }
        }
      }

      if (collapseItems.length) {
        for (const item of collapseItems) {
          const entry = find(entries.value, { eid: item })
          if (entry) {
            console.log('close', entry)
            call('graphql/collapseEntry', entry)
          }
        }
      }
    })

    return {
      active,
      activeItem,
      chipPaneSize,
      items,
      loading,
      loadChildren,
      open,
      openMenu,
      treeViewLabelClick,
    }
  },
}
</script>

<style lang="sass">
  .main-container
    padding: 0px
    height: calc(100vh - 48px - 56px)

  #vuer-panels
    .splitpanes__pane
      background-color: #181818

    .splitpanes__splitter
      background-color: #363636
</style>
